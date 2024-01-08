from app import db, etherscan, w3
from app.models.base import Base
import json
from app.models.address import Address

class Event(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
    timestamp = db.Column(db.Integer)
    payload_json = db.Column(db.Text)
    # IDENTIFIERS:
    block_hash = db.Column(db.String(66))
    transaction_hash = db.Column(db.String(66))
    log_index = db.Column(db.Integer)

    @property
    def payload(self):
        return json.loads(self.payload_json)

    @property
    def int(self):
        return int

    @property
    def bytearray(self):
        return bytearray

    @property
    def w3(self):
        return w3

    @property
    def etherscan(self):
        return etherscan

    @property
    def Address(self):
        return Address

