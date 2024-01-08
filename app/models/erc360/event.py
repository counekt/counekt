from app import db
from app.models.base import Base
import json

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
