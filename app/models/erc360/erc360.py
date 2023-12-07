from app import db, w3
import app.funcs as funcs
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.location_base import LocationBase
from flask import url_for
import app.models as models
import json
import app.funcs as funcs
from app.models.profile.wallet import _permits
import math
from markupsafe import Markup

class ERC360(db.Model, Base, LocationBase):

    def __init__(self,creator,**kwargs):
        super(ERC360, self).__init__(**{k: kwargs[k] for k in kwargs})
        self.timeline_last_updated_at = 0
        models.Permit.create_initial_permits(self,creator)
        # do custom initialization here
        self.photo = Photo(filename="photo", path=f"static/erc360s/{self.address}/photo/", replacement="/static/images/erc360.jpg")

    id = db.Column(db.Integer, primary_key=True) # DELETE THIS IN FUTURE
    active = db.Column(db.Boolean,default=True)
    address = db.Column(db.String(42)) # ETH token address
    block = db.Column(db.Integer) # ETH block number
    current_clock = db.Column(db.Integer, default=0) # Clock
    total_supply = db.Column(db.Integer, default=0) # Total Amount of tokens

    events_last_updated_at = db.Column(db.Integer) # ETH block number
    token_ids_last_updated_at = db.Column(db.Integer) # ETH block number
    bank_exchanges_last_updated_at = db.Column(db.Integer) # ETH block number
    dividend_claims_last_updated_at = db.Column(db.Integer) # ETH block number
    referendum_votes_last_updated_at = db.Column(db.Integer) # ETH block number

    symbol = db.Column(db.String)
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    photo_id = db.Column(db.Integer, db.ForeignKey('photo.id', ondelete="cascade"))
    photo = db.relationship("Photo", foreign_keys=[photo_id])

    actions = db.relationship(
        'Action', backref='erc360', lazy='dynamic',
        foreign_keys='Action.erc360_id', order_by="Action.timestamp", passive_deletes=True)

    token_ids = db.relationship(
        'ERC360TokenId', backref='erc360', lazy='dynamic',
        foreign_keys='ERC360TokenId.erc360_id',order_by="ERC360TokenId.token_id",passive_deletes=True)

    dividends = db.relationship(
        'Dividend', backref='erc360', lazy='dynamic',
        foreign_keys='Dividend.erc360_id',order_by="Dividend.clock", passive_deletes=True)

    referendums = db.relationship(
        'Referendum', backref='erc360', lazy='dynamic',
        foreign_keys='Referendum.erc360_id',order_by="Referendum.timestamp",passive_deletes=True)

    banks = db.relationship(
        'Bank', lazy='dynamic', backref='erc360', 
        foreign_keys='Bank.erc360_id', passive_deletes=True)

    permits = db.relationship(
        'Permit', backref='erc360', lazy='dynamic',
        foreign_keys='Permit.erc360_id', passive_deletes=True, cascade="all, delete")

    def get_timeline(self):
        contract = w3.eth.contract(address=self.address,abi=funcs.get_abi())
        events = contract.events.ActionTaken.getLogs(fromBlock=self.block)
        return [funcs.decode_event_payload(e) for e in events]

    def update_timeline(self):
        contract = self.get_w3_contract()
        events = contract.events.ActionTaken.getLogs(fromBlock=self.timeline_last_updated_at or self.block)
        for e in events:
            if not self.events.filter_by(block_hash=e.blockHash.hex(), transaction_hash=e.transactionHash.hex(),log_index=e.logIndex).first():
                timestamp = w3.eth.getBlock(e.blockNumber).timestamp
                payload_json = json.dumps(funcs.decode_event_payload(e))
                event = models.Event(block_hash=e.blockHash.hex(), transaction_hash=e.transactionHash.hex(),log_index=e.logIndex,timestamp=timestamp,payload_json=payload_json)
                self.events.append(event)
                decoded_payload = funcs.decode_event_payload(e)
                if decoded_payload["func"] == "iD": # Issue Dividend
                    if not self.dividends.filter_by(clock=decoded_payload["clock"]).first():
                        dividend = models.Dividend(clock=decoded_payload["clock"],value=decoded_payload["value"],token_address=decoded_payload["tokenAddress"])
                        bank = self.banks.filter_by(name=decoded_payload["bankName"])
                        bank.subtract_value(decoded_payload["value"],decoded_payload["tokenAddress"])
                if decoded_payload["func"] == "dD": # Dissolve Dividend
                    dividend = self.dividends.filter_by(clock=decoded_payload["clock"]).first()
                    if dividend:
                        address = contract.functions.getDividendToken(decoded_payload["clock"]).call()
                        residual = contract.functions.getDividendResidual(decoded_payload["clock"]).call()
                        dividend.dissolved = True
                        main_bank = self.banks.filter_by(name="main")
                        main_bank.register_token(address)
                        main_bank.add_value(residual,address)
                if decoded_payload["func"] == "iR": # Issue Referendum
                    if not self.referendums.filter_by(clock=decoded_payload["clock"]).first():
                        viable_amount = contract.functions.totalSupplyByClock(decoded_payload["clock"]).call()
                        referendum = models.Referendum(clock=decoded_payload["clock"],viable_amount=viable_amount)
                        referendum_info = contract.functions.infoByReferendum(decoded_payload["clock"]).call()
                        for i, func in enumerate(referendum_info[1]): # add proposals if any
                            proposal = models.Proposal(func=func,args=referendum_info[2][i])
                            referendum.proposals.add(proposal)
                if decoded_payload["func"] == "cB": # Create Bank
                    if not self.banks.filter_by(name=decoded_payload["name"]).first():
                        bank = models.Bank(name=decoded_payload["name"])
                        admin = models.Wallet.get_or_register(address=decoded_payload["admin"])
                        bank.admins.add(admin)
                if decoded_payload["func"] == "dB": # Delete Bank
                    bank = self.banks.filter_by(name=decoded_payload["name"]).first()
                    if bank:
                        db.session.delete(bank)
                if decoded_payload["func"] == "sP": # Set Permit
                    wallet = models.Wallet.get_or_register(address=decoded_payload["account"])
                    permit = self.permits.filter_by(name=decoded_payload["name"],wallet=wallet).first()
                    if not permit:
                        permit = models.Permit(wallet=wallet,name=decoded_payload["name"])
                        self.permits.append(permit)
                    permit.state = decoded_payload["state"]
                if e["args"]["func"] == "iP": # Implement Proposal
                    referendum = self.referendums.filter_by(clock=decoded_payload["clock"]).first()
                    proposal = referendum.proposals.filter_by(index=decoded_payload["index"]).first()
                    if not proposal:
                        raise Exception("Proposal does not exist...")
                    proposal.implemented = True
                if e["args"]["func"] == "aA": # Add Admin
                    bank = self.banks.filter_by(name=decoded_payload["name"]).first()
                    admin = models.Wallet.get_or_register(address=decoded_payload["admin"])
                    if not bank:
                        raise Exception("Bank does not exist...")
                    bank.admins.append(admin)
                if e["args"]["func"] == "rA": # Remove Admin
                    bank = self.banks.filter_by(name=decoded_payload["name"]).first()
                    admin = bank.admins.filter_by(address=decoded_payload["tokenAddress"]).first()
                    if not bank:
                        raise Exception("Bank does not exist...")
                    banks.admins.remove(admin)
                if e["args"]["func"] == "tT": # Transfer Token
                    bank = self.banks.filter_by(name=decoded_payload["fromBankName"]).first()
                    if not bank:
                        raise Exception("Bank does not exist...")
                    bank.external_transfers.append(models.ExternalTokenTransfer(recipient_address=decoded_payload["to"]))
                    bank.subtract_value(decoded_payload["value"],decoded_payload["tokenAddress"])
                    self.liquid.subtract_value(decoded_payload["value"],decoded_payload["tokenAddress"])
                if e["args"]["func"] == "mT": # Transfer Token
                    fromBank = self.banks.filter_by(name=decoded_payload["fromBankName"]).first()
                    toBank = self.banks.filter_by(name=decoded_payload["toBankName"]).first()
                    if not frombank or toBank:
                        raise Exception("fromBank or toBank does not exist...")
                    fromBank.subtract_value(decoded_payload["value"],decoded_payload["tokenAddress"])
                    toBank.add_value(decoded_payload["value"],decoded_payload["tokenAddress"])
                if e["args"]["func"] == "iS": # Mint
                    pass
                if e["args"]["func"] == "uT": # Unregister Token
                    token = self.liquid.tokens.filter_by(address=decoded_payload["tokenAddress"]).first()
                    self.liquid.tokens.remove(token)
                if e["args"]["func"] == "rT": # Register Token
                    token = self.liquid.tokens.filter_by(address=decoded_payload["tokenAddress"]).first()
                    if not token:
                        token = models.TokenAmount(address=decoded_payload["tokenAddress"])
                        self.liquid.tokens.append(token)
                if e["args"]["func"] == "lE": # Liquidize Entity
                    self.active = False
                if e.blockNumber > int(self.timeline_last_updated_at or self.block):
                    self.timeline_last_updated_at = e.blockNumber

    def update_ownership(self):
        contract = self.get_w3_contract()
        # Register new token id's
        updated_token_ids = contract.events.NewTokenId.getLogs(fromBlock=self.token_ids_last_updated_at or self.block)
        for ntid in updated_token_ids:
            # IF NOT ALREADY THERE
            if not self.token_ids.filter_by(token_id=ntid.args.tokenId).first():
                timestamp = w3.eth.getBlock(ntid.blockNumber).timestamp
                # REGISTER OLD TOKEN-IDS OF ACCOUNT AS EXPIRED
                wallet = models.Wallet.register(address=ntid.args.account)
                non_expired = self.token_ids.filter(models.ERC360TokenId.wallet_id == wallet.id, models.ERC360TokenId.is_expired != True)
                for ne in non_expired:
                    exp = contract.functions.expirationOf(ne.token_id).call()
                    ne.expire(exp) # FAILS TO ACCOUNT FOR MULTIPLE EXPS AT ONCE
                    print(f"yessir... expiration: {exp}")
                    ne.expiration_timestamp = timestamp
                
                # REGISTER NEW TOKEN-ID
                amount = contract.functions.amountOf(ntid.args.tokenId).call()
                print(f"\nTOKEN ID: {ntid.args.tokenId}\n")
                token_id = models.ERC360TokenId(token_id=ntid.args.tokenId,wallet=wallet,amount=amount)
                token_id.creation_timestamp = timestamp
                self.token_ids.append(token_id)

            if ntid.blockNumber > int(self.token_ids_last_updated_at or self.block):
                self.token_ids_last_updated_at = ntid.blockNumber
            
        # For reference to decide which token id's are currently valid and which ones aren't
        self.current_clock = contract.functions.currentClock().call()
        self.total_supply = contract.functions.totalSupplyAt(self.current_clock).call()

    def update_structure(self):
        contract = self.get_w3_contract()
        for bank in self.banks:
            for token_amount in bank.token_amounts:
                token_address = token_amount.token.address
                amount_wei = contract.functions.bankBalanceOf(bank.permit.bytes,token_address).call()
                token_amount.amount = amount_wei

        """
        # Dividend Claims
        new_claims = contract.events.DividendClaimed.getLogs(fromBlock=self.dividend_claims_last_updated_at or self.block)
        for nc in new_claims:
            dividend = self.dividends.filter_by(clock=nc.args.dividendClock).first()
            token_id = self.token_ids.filter(models.ERC360TokenId.owner.has(address=nc.args.by)).first()
            if not dividend or not token_id:
                raise Exception("Dividend or ERC360TokenId does not exist...")
            claim = models.DividendClaim.filter_by(dividend=dividend,token_id=token_id).first()
            if not claim:
                claim = models.DividendClaim(value=nc.args.value)
                claim.value = nc.args.value
                claim.token_id = token_id
                dividend.claims.append(claim)
            if nc.blockNumber > int(self.dividend_claims_last_updated_at or self.block):
                self.dividend_claims_last_updated_at = ns.blockNumber
        # Referendum Votes
        new_votes = contract.events.VoteCast.getLogs(fromBlock=self.referendum_votes_last_updated_at or self.block)
        for nv in new_votes:
            referendum = self.referendums.filter_by(clock=nv.args.referendumClock).first()
            token_id = self.token_ids.filter(models.ERC360TokenId.owner.has(address=nv.args.by)).first()
            if not referendum or not token_id:
                raise Exception("Referendum or ERC360TokenId does not exist...")
            vote = models.Vote.filter_by(referendum=referendum,token_id=token_id).first()
            if not vote:
                vote = models.Vote(token_id=token_id, in_favor=nv.args.favor)
                referendum.votes.append(vote)
                referendum.cast_amount += vote.token_id.amount
                referendum.in_favor_amount += vote.token_id.amount if nv.args.favor else 0
            if nv.blockNumber > int(self.referendum_votes_last_updated_at or self.block):
                self.referendum_votes_last_updated_at = ns.blockNumber
        """
    def get_w3_contract(self):
        contract = w3.eth.contract(address=self.address,abi=funcs.get_abi())
        return contract

    def get_token_id_by_clock(self,account,clock):
        return self.token_ids.filter(models.ERC360TokenId.wallet.has(address=account)).filter(models.ERC360TokenId.token_id <= self.current_clock < models.ERC360TokenId.expiration_clock).first() 

    @hybrid_property
    def current_token_ids(self):
        return self.token_ids.filter(models.ERC360TokenId.is_expired != True).order_by(models.ERC360TokenId.amount.desc()) if self.token_ids.first() else []

    @property
    def href(self):
        return url_for("erc360.erc360", address=self.address)

    @hybrid_property
    def identifier(self):
        return self.address

    @property
    def log_total_supply(self):
        return round(math.log2(self.total_supply or 1),1)

    @property
    def log_max_supply(self):
        return 256

    @property
    def pretty_exponential_total_supply(self):
        total_supply = self.total_supply or 0
        if total_supply < 10000:
            return total_supply
        mantissa, exponent = '{:.2e}'.format(total_supply).split('e')
        return Markup(f"{math.floor(float(mantissa)*100)/100} x 10<sup>{int(exponent)}</sup>");



    def __repr__(self):
        return "<ERC360 {}>".format(self.address)
