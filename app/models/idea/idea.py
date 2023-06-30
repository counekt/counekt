from app import db, w3
import app.funcs as funcs
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.locationBase import locationBase
from flask import url_for
import app.models.idea.group as _group
import app.models.idea.event as _event
import app.models.idea.shard as _shard
import json

class Idea(db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True) # DELETE THIS IN FUTURE
    address = db.Column(db.String(42)) # ETH address
    block = db.Column(db.Integer) # ETH block number
    current_clock = db.Column(db.Integer) # Shardable clock
    timeline_last_updated_at = db.Column(db.Integer) # ETH block number
    ownership_last_updated_at = db.Column(db.Integer) # ETH block number
    symbol = "€"
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete="cascade"))
    group = db.relationship("Group", foreign_keys=[group_id])
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    photo_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    photo = db.relationship("Photo", foreign_keys=[photo_id])

    events = db.relationship(
        'Event', backref='entity', lazy='dynamic',
        foreign_keys='Event.entity_id')

    shards = db.relationship(
        'Shard', backref='entity', lazy='dynamic',
        foreign_keys='Shard.entity_id')

    def __init__(self, **kwargs):
        super(Idea, self).__init__(**{k: kwargs[k] for k in kwargs if k != "members"})
        self.timeline_last_updated_at = 0
        # do custom initialization here
        members = kwargs["members"]
        self.group = _group.Group(members=members)
        for user in members:
            self.add_member(user)
        self.photo = Photo(filename="photo", path=f"static/ideas/{self.handle}/photo/", replacement="/static/images/idea.jpg")

    def add_member(self, user):
        self.group.members.append(user)

    def remove_member(self, user):
        self.group.members.remove(user)

    def delete(self):
        for m in self.group.members:
            m.ideas.remove(self)
        if self.exists_in_db:
            db.session.delete(self.group)
            db.session.delete(self)

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
                event = _event.Event(block_hash=e.blockHash.hex(), transaction_hash=e.transactionHash.hex(),log_index=e.logIndex,timestamp=timestamp,payload_json=payload_json)
                self.events.append(event)
                if e.blockNumber > int(self.timeline_last_updated_at or self.block):
                    self.timeline_last_updated_at = e.blockNumber

        # TO BE CONTINUED...

    def update_ownership(self):
        contract = self.get_w3_contract()
        start_at = self.ownership_last_updated_at
        # Register new shards
        new_shards = contract.events.NewShard.getLogs(fromBlock=start_at or self.block)
        for ns in new_shards:
            if not self.shards.filter_by(identity=ns.args.shard).first():
                shard = _shard.Shard(identity=ns.args.shard,owner_address=ns.args.owner,creation_clock=ns.args.creationClock)
                shard_info = contract.functions.infoByShard(ns.args.shard).call()
                shard.numerator, shard.denominator = shard_info[0], shard_info[1]
                shard.creation_timestamp = w3.eth.getBlock(ns.blockNumber).timestamp
                self.shards.append(shard)
                if ns.blockNumber > int(self.ownership_last_updated_at or self.block):
                    self.ownership_last_updated_at = ns.blockNumber
        # Register expired shards
        expired_shards = contract.events.ExpiredShard.getLogs(fromBlock=start_at or self.block)
        for es in expired_shards:
            shard = self.shards.filter_by(identity=es.args.shard).first()
            shard.expiration_clock = es.args.expiration_clock
            shard.expiration_timestamp = w3.eth.getBlock(es.blockNumber).timestamp
            if es.blockNumber > int(self.ownership_last_updated_at or self.block):
                self.ownership_last_updated_at = es.blockNumber
        # For reference to decide which shards are currently valid and which ones aren't
        self.current_clock = contract.functions.getCurrentClock().call()

    def get_w3_contract(self):
        contract = w3.eth.contract(address=self.address,abi=funcs.get_abi())
        return contract

    def get_shard_by_clock(self,owner_address,clock):
        return self.shards.filter_by(owner_address=owner_address).filter(_shard.Shard.creation_clock <= self.current_clock < _shard.expiration_clock).first()

    @hybrid_property
    def valid_shards(self):
        return self.shards.filter(self.current_clock < _shard.Shard.expiration_clock).order_by(_shard.Shard.percentage.desc())

    @property
    def href(self):
        return url_for("idea.idea", handle=self.handle)

    @hybrid_property
    def identifier(self):
        return self.handle

    def __repr__(self):
        return "<Idea {}{}>".format(self.symbol,self.handle)
