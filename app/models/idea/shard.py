from app import db
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class Shard(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	identity = db.Column(db.LargeBinary(32)) # ETH bytes32
	owner_address = db.Column(db.String(42)) # ETH address
	amount = db.Column(db.Integer) # Fraction Numerator

	""" Representation as Big Integers will likely run out year 2262, Fri on Apr 11 """
	
	# Used for representation in accordance to reality
	creation_timestamp = db.Column(db.BigInteger) # ETH Block push timestamp
	expiration_timestamp = db.Column(db.BigInteger, default=9223372036854775807) # ETH Block expiration timestamp

	# Used for representation in accordance to the contract machinery
	creation_clock = db.Column(db.BigInteger) # Shardable Clock push time
	expiration_clock = db.Column(db.BigInteger, default=9223372036854775807) # Shardable Clock expiration time

