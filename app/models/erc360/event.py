from app import db, etherscan, w3
from app.models.base import Base
import json
from app.models.address import Address
from datetime import datetime
from sqlalchemy.ext.hybrid import hybrid_property, hybrid_method
from sqlalchemy.dialects.postgresql import JSONB

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

    @property
    def time(self):
        return datetime.fromtimestamp(self.timestamp).strftime("%d. %b %Y %H:%M").lower()

    @hybrid_method
    def is_bank_event(self):        
        #                                                            receipt, dividend, callExternal, transferFunds, moveFunds
        return db.cast(self.payload_json,JSONB)['methodId'].astext.in_(['0x','0x873fdde7','0x3b51634f','0x7ab1f504','0x3fb3a2d7'])
        