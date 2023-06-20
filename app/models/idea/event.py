from app import db
from app.models.base import Base

class Event(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
    timestamp = db.Column(db.Integer)
    payload_json = db.Column(db.Text)
    # IDENTIFIERS:
    block_hash = db.Column(db.String(64))
    transaction_hash = db.Column(db.String(64))
    log_index = db.Column(db.Integer)

