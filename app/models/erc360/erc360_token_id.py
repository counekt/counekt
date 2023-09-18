from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class ERC360TokenId(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	wallet_id = db.Column(db.Integer, db.ForeignKey('wallet.id', ondelete='CASCADE'))
	owner = db.relationship("Wallet", foreign_keys=[wallet_id], backref="erc360_token_ids")
	
	amount = db.Column(db.Integer) # Amount

	""" Representation as Big Integers will likely run out year 2262, Fri on Apr 11 """
	
	# Used for representation in accordance to reality
	creation_timestamp = db.Column(db.Integer) # ETH Block push timestamp
	expiration_timestamp = db.Column(db.Integer, default=9223372036854775807)

	# Used for representation in accordance to the contract machinery
	creation_clock = db.Column(db.BigInteger) # Clock push time
	expiration_clock = db.Column(db.BigInteger, default=9223372036854775807) # Token Id Clock expiration time

	@property
	def is_expired(self):
		return self.expiration_clock != 9223372036854775807


	def __repr__(self):
		return '<ERC360TokenId {}>'.format(self.creation_clock)

