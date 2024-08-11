from app import db, w3, etherscan
import app.funcs as funcs
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from app.models.static.photo import Photo
from app.models.base import Base
from flask import url_for
import app.models as models
import json
import app.funcs as funcs
from app.models.profile.wallet import _permits
import math
from markupsafe import Markup

class ERC360(db.Model, Base):

    id = db.Column(db.Integer, primary_key=True) # DELETE THIS IN FUTURE
    active = db.Column(db.Boolean,default=True)
    address = db.Column(db.String(42)) # ETH token address
    block = db.Column(db.Integer) # ETH block number
    current_clock = db.Column(db.Integer, default=0) # Clock
    total_supply = db.Column(db.Integer, default=0) # Total Amount of tokens

    timeline_last_updated_at = db.Column(db.Integer) # ETH block number
    shards_last_updated_at = db.Column(db.Integer) # ETH block number
    bank_exchanges_last_updated_at = db.Column(db.Integer) # ETH block number
    dividend_claims_last_updated_at = db.Column(db.Integer) # ETH block number
    referendums_last_updated_at = db.Column(db.Integer) # ETH block number

    symbol = db.Column(db.String)
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    photo_id = db.Column(db.Integer, db.ForeignKey('file.id', ondelete="cascade"))
    photo = db.relationship("Photo", foreign_keys=[photo_id])

    location_id = db.Column(db.Integer, db.ForeignKey('location.id'))
    location = db.relationship("Location", foreign_keys=[location_id])

    events = db.relationship(
        'Event', backref='erc360', lazy='dynamic',
        foreign_keys='Event.erc360_id', order_by="Event.timestamp", passive_deletes=True)

    shards = db.relationship(
        'ERC360Shard', backref='erc360', lazy='dynamic',
        foreign_keys='ERC360Shard.erc360_id',order_by="ERC360Shard.identifier",passive_deletes=True)

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
        foreign_keys='Permit.erc360_id', passive_deletes=True)

    @hybrid_property
    def bank_events(self):
        return self.events.filter(models.Event.is_bank_event() == True)

    def __init__(self,creator,address,block,**kwargs):
        super(ERC360, self).__init__(**{k: kwargs[k] for k in kwargs})
        self.address = address
        self.block = block
        self.timeline_last_updated_at = block
        self.shards_last_updated_at = block
        self.referendums_last_updated_at = block
        models.Permit.create_initial_permits(self,creator)
        # do custom initialization here
        self.photo = Photo(filename="photo", path=f"static/erc360s/{address}/photo/", replacement="/static/images/erc360.jpg")
        self.location = models.Location()

    def get_timeline(self):
        return [e.payload for e in self.events]

    def update_timeline(self):
        contract = self.get_w3_contract()
        transacts = etherscan.get_transactions_of(address=contract.address,startblock=self.timeline_last_updated_at)
        print("\n"*10+f"TRANSACTS"+"\n"*10)
        for t in transacts:
            if not self.events.filter_by(block_hash=t["blockHash"], transaction_hash=t["hash"],log_index=t["transactionIndex"]).first():
                timestamp = w3.eth.getBlock(int(t["blockNumber"])).timestamp
                decoded_payload = funcs.decode_transaction_payload(t)
                payload_json = json.dumps(decoded_payload)
                event = models.Event(block_hash=t["blockHash"], transaction_hash=t["hash"],log_index=t["transactionIndex"],timestamp=timestamp,payload_json=payload_json)
                self.events.append(event)
                print("\n"*10+f"TX STATUS: {decoded_payload['txreceipt_status']}"+"\n"*10)
                if decoded_payload["txreceipt_status"] == "1":
                    print("\n"*10+"HERE IS VALID METHOD"+"\n"*10)

                    if decoded_payload["methodId"] == '0x': # on simple receipt
                        # Just register the event, update_ownership takes care of the rest

                        main_bank = models.Bank.get_or_register(erc360=self,permit_bytes=bytes(32))
                        main_bank.add_amount(int(t["value"]),"0x0000000000000000000000000000000000000000")
                        print("\n"*10+f"AMOUNT ADDED: {t['value']}"+"\n"*10)
                    if decoded_payload["methodId"] == '0x8ab73cf9': # Set Permit
                        wallet = models.Wallet.get_or_register(address=decoded_payload["args"]["account"])
                        permit = models.Permit.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["permit"]))
                        if decoded_payload["args"]["status"] == True:
                            permit.wallets.append(wallet)
                        else:
                            permit.wallets.remove(wallet)
                    if decoded_payload["methodId"] == '0x9a9abf85': # Set Permit Parent
                        permit = models.Permit.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["permit"]))
                        parent = models.Permit.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["parent"]))
                        permit.parent = parent
                    if decoded_payload["methodId"] == '0x40c10f19': # Mint
                        # Just register the event, update_ownership takes care of the rest 
                        pass
                    if decoded_payload["methodId"] == '0x873fdde7': # Issue Dividend 
                        if not self.dividends.filter_by(clock=0).first():
                            dividend = models.Dividend(clock=decoded_payload["args"]["clock"],amount=int(decoded_payload["args"]["amount"]),token=decoded_payload["args"]["token"])
                            bank = models.Bank.get_or_register(erc360=self,permit_bytes=decoded_payload["args"]["bank"])
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
                        bank = models.Bank.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["fromBank"]))
                        bank.subtract_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                        print("\n"*10+f"AMOUNT SUBTRACTED: {t['value']}"+"\n"*10)
                    if decoded_payload["methodId"] == "0x3fb3a2d7": # Move Funds
                        fromBank = models.Bank.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["fromBank"]))
                        toBank = models.Bank.get_or_register(erc360=self,permit_bytes=bytearray.fromhex(decoded_payload["args"]["toBank"]))
                        fromBank.subtract_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                        toBank.add_amount(int(decoded_payload["args"]["amount"]),decoded_payload["args"]["token"])
                if int(t["blockNumber"]) > int(self.timeline_last_updated_at):
                    self.timeline_last_updated_at = int(t["blockNumber"])

    def update_ownership(self):
        contract = self.get_w3_contract()
        # Register new token id's
        updated_shards = contract.events.NewShard.getLogs(fromBlock=self.shards_last_updated_at or self.block)
        for ntid in updated_shards:
            # IF NOT ALREADY THERE
            if not self.shards.filter_by(identifier=ntid.args.shardId).first():
                timestamp = w3.eth.getBlock(ntid.blockNumber).timestamp
                # REGISTER OLD TOKEN-IDS OF ACCOUNT AS EXPIRED
                wallet = models.Wallet.get_or_register(address=ntid.args.account)
                non_expired_shards = self.shards.filter(models.ERC360Shard.wallet_id == wallet.id, models.ERC360Shard.is_expired != True)
                for shard in non_expired_shards:
                    exp = contract.functions.expirationOf(shard.identifier).call()
                    shard.expire(exp) # FAILS TO ACCOUNT FOR MULTIPLE EXPS AT ONCE
                    print(f"yessir... expiration: {exp}")
                    shard.expiration_timestamp = timestamp
                
                # REGISTER NEW TOKEN-ID
                amount = contract.functions.amountOf(ntid.args.shardId).call()
                print(f"\nTOKEN ID: {ntid.args.shardId}\n")
                shard = models.ERC360Shard(identifier=ntid.args.shardId,wallet=wallet,amount=amount)
                shard.creation_timestamp = timestamp
                self.shards.append(shard)

            if ntid.blockNumber > int(self.shards_last_updated_at or self.block):
                self.shards_last_updated_at = ntid.blockNumber
            
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
            shard = self.shards.filter(models.ERC360Shard.owner.has(address=nc.args.by)).first()
            if not dividend or not shard:
                raise Exception("Dividend or ERC360Shard does not exist...")
            claim = models.DividendClaim.filter_by(dividend=dividend,shard=shard).first()
            if not claim:
                claim = models.DividendClaim(value=nc.args.value)
                claim.value = nc.args.value
                claim.shard = shard
                dividend.claims.append(claim)
            if nc.blockNumber > int(self.dividend_claims_last_updated_at or self.block):
                self.dividend_claims_last_updated_at = ns.blockNumber
        # Referendum Votes
        new_votes = contract.events.VoteCast.getLogs(fromBlock=self.referendum_votes_last_updated_at or self.block)
        for nv in new_votes:
            referendum = self.referendums.filter_by(clock=nv.args.referendumClock).first()
            shard = self.shards.filter(models.ERC360Shard.owner.has(address=nv.args.by)).first()
            if not referendum or not shard:
                raise Exception("Referendum or ERC360Shard does not exist...")
            vote = models.Vote.filter_by(referendum=referendum,shard=shard).first()
            if not vote:
                vote = models.Vote(shard=shard, in_favor=nv.args.favor)
                referendum.votes.append(vote)
                referendum.cast_amount += vote.shard.amount
                referendum.in_favor_amount += vote.shard.amount if nv.args.favor else 0
            if nv.blockNumber > int(self.referendum_votes_last_updated_at or self.block):
                self.referendum_votes_last_updated_at = ns.blockNumber
        """


    def clear_events(self,timestamp):
        for event in self.events.filter(models.Event.timestamp >= timestamp).all():
            db.session.delete(event)


    def get_w3_contract(self):
        contract = w3.eth.contract(address=self.address,abi=funcs.get_abi())
        return contract

    def get_shard_by_clock(self,account,clock):
        return self.shards.filter(models.ERC360Shard.wallet.has(address=account)).filter((models.ERC360Shard.identifier <= self.current_clock < models.ERC360Shard.expiration_clock) or not models.ERC360Shard.expiration_clock).first() 

    @hybrid_property
    def current_shards(self):
        return self.shards.filter(models.ERC360Shard.is_expired != True).order_by(models.ERC360Shard.amount.desc()) if self.shards.first() else []

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

    @classmethod
    def get_explore_query(cls, latitude, longitude, radius):
        query = cls.query.join(models.Location).filter(models.Location.is_in_explore_query(latitude, longitude, radius))
        return query

    def __repr__(self):
        return "<ERC360 {}>".format(self.address)
