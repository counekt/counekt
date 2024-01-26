from app import db, w3, etherscan
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

    def __init__(self,creator,address,**kwargs):
        super(ERC360, self).__init__(**{k: kwargs[k] for k in kwargs})
        self.address = address
        self.timeline_last_updated_at = 0
        models.Permit.create_initial_permits(self,creator)
        # do custom initialization here
        self.photo = Photo(filename="photo", path=f"static/erc360s/{address}/photo/", replacement="/static/images/erc360.jpg")

    id = db.Column(db.Integer, primary_key=True) # DELETE THIS IN FUTURE
    active = db.Column(db.Boolean,default=True)
    address = db.Column(db.String(42)) # ETH token address
    block = db.Column(db.Integer) # ETH block number
    current_clock = db.Column(db.Integer, default=0) # Clock
    total_supply = db.Column(db.Integer, default=0) # Total Amount of tokens

    timeline_last_updated_at = db.Column(db.Integer) # ETH block number
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

    events = db.relationship(
        'Event', backref='erc360', lazy='dynamic',
        foreign_keys='Event.erc360_id', order_by="Event.timestamp", passive_deletes=True)

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

    @hybrid_property
    def bank_events(self):
        return self.events.filter(models.Event.is_bank_event() == True)

    def get_timeline(self):
        return [e.payload for e in self.events]

    def update_timeline(self):
        contract = self.get_w3_contract()
        transacts = etherscan.get_transactions_of(address=contract.address,startblock=self.timeline_last_updated_at)
        print(transacts)
        for t in transacts:
            print(t,type(t))
            if not self.events.filter_by(block_hash=t["blockHash"], transaction_hash=t["hash"],log_index=t["transactionIndex"]).first():
                print(t)
                timestamp = w3.eth.getBlock(int(t["blockNumber"])).timestamp
                decoded_payload = funcs.decode_transaction_payload(t)
                payload_json = json.dumps(decoded_payload)
                event = models.Event(block_hash=t["blockHash"], transaction_hash=t["hash"],log_index=t["transactionIndex"],timestamp=timestamp,payload_json=payload_json)
                self.events.append(event)
                print(f"\n{decoded_payload}\n")
                if decoded_payload["txreceipt_status"] == "1":
                    print("HERE IS VALID METHOD")

                    if decoded_payload["methodId"] == '0x': # on simple receipt
                        # Just register the event, update_ownership takes care of the rest
                        """
                        main_bank = models.Bank.get_or_register(erc360=self,bytes=bytes(32))
                        main_bank.add_amount(int(t["value"]),"0x0000000000000000000000000000000000000000")
                        """
                    if decoded_payload["methodId"] == '0x8ab73cf9': # Set Permit
                        wallet = models.Wallet.get_or_register(address=decoded_payload["args"]["account"])
                        permit = models.Permit.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["permit"]))
                        if decoded_payload["args"]["status"] == True:
                            permit.wallets.append(wallet)
                        else:
                            permit.wallets.remove(wallet)
                        print("HERE IS SETPERMIT METHOD HANDLING")
                    if decoded_payload["methodId"] == '0x9a9abf85': # Set Permit Parent
                        permit = models.Permit.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["permit"]))
                        parent = models.Permit.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["parent"]))
                        permit.parent = parent
                    if decoded_payload["methodId"] == '0x40c10f19': # Mint
                        # Just register the event, update_ownership takes care of the rest 
                        pass
                    if decoded_payload["methodId"] == '0x873fdde7': # Issue Dividend 
                        if not self.dividends.filter_by(clock=0).first():
                            dividend = models.Dividend(clock=decoded_payload["args"]["clock"],amount=int(decoded_payload["args"]["amount"]),token=decoded_payload["args"]["token"])
                            bank = models.Bank.get_or_register(erc360=self,permit=decoded_payload["args"]["bank"])
                            bank.subtract_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                    if decoded_payload["methodId"] == '0x3598f3f3': # Issue Vote
                        if not self.referendums.filter_by(clock=decoded_payload["args"]["clock"]).first():
                            viable_amount = contract.functions.totalSupplyByClock(decoded_payload["args"]["clock"]).call()
                            referendum = models.Referendum(clock=decoded_payload["args"]["clock"],viable_amount=viable_amount)
                            referendum_info = contract.functions.infoByReferendum(decoded_payload["args"]["clock"]).call()
                            for i, func in enumerate(referendum_info[1]): # add proposals if any
                                proposal = models.Proposal(func=func,args=referendum_info[2][i])
                                referendum.proposals.add(proposal)
                    if decoded_payload["methodId"] == "0x74c8df12": # Implement Resolution
                        referendum = models.Referendum.get_or_register(erc360=self,event_id=decoded_payload["args"]["event_id"])
                        proposal = models.Proposal.get_or_register(referendum=referendum,index=decoded_payload["args"]["index"])
                        proposal.implemented = True
                    if decoded_payload["methodId"] == "0x7ab1f504": # Transfer Funds From Bank
                        bank = models.Bank.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["fromBank"]))
                        #bank.subtract_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                    if decoded_payload["methodId"] == "0x3fb3a2d7": # Move Funds
                        fromBank = models.Bank.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["fromBank"]))
                        toBank = models.Bank.get_or_register(erc360=self,bytes=bytearray.fromhex(decoded_payload["args"]["toBank"]))
                        """
                        fromBank.subtract_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                        toBank.add_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                        """
                if int(t["blockNumber"]) > int(self.timeline_last_updated_at or self.block):
                    self.timeline_last_updated_at = int(t["blockNumber"])

    def update_ownership(self):
        contract = self.get_w3_contract()
        # Register new token id's
        updated_token_ids = contract.events.NewTokenId.getLogs(fromBlock=self.token_ids_last_updated_at or self.block)
        for ntid in updated_token_ids:
            # IF NOT ALREADY THERE
            if not self.token_ids.filter_by(token_id=ntid.args.tokenId).first():
                timestamp = w3.eth.getBlock(ntid.blockNumber).timestamp
                # REGISTER OLD TOKEN-IDS OF ACCOUNT AS EXPIRED
                wallet = models.Wallet.get_or_register(address=ntid.args.account)
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
