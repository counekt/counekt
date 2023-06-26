from app import db
from app.models.base import Base

class Shard(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	identity = db.Column(db.LargeBinary(32)) # ETH bytes32
	owner_address = db.Column(db.String(42)) # ETH address
	numerator = db.Column(db.Integer) # Fraction Numerator
	denominator = db.Column(db.Integer) # Fraction Numerator
	creation_clock = db.Column(db.Integer) # Shardable Clock push time

