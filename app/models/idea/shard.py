from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class Shard(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	owner_id = db.Column(db.Integer, db.ForeignKey('wallet.id', ondelete='CASCADE'))
	owner = db.relationship("Wallet", foreign_keys=[owner_id])
	
	identity = db.Column(db.LargeBinary(32)) # ETH bytes32
	amount = db.Column(db.Integer) # Amount

	""" Representation as Big Integers will likely run out year 2262, Fri on Apr 11 """
	
	# Used for representation in accordance to reality
	creation_timestamp = db.Column(db.BigInteger) # ETH Block push timestamp
	expiration_timestamp = db.Column(db.BigInteger, default=9223372036854775807) # ETH Block expiration timestamp

	# Used for representation in accordance to the contract machinery
	creation_clock = db.Column(db.BigInteger) # Shardable Clock push time
	expiration_clock = db.Column(db.BigInteger, default=9223372036854775807) # Shardable Clock expiration time

	def __repr__(self):
		return '<Shard {}>'.format(self.amount)

