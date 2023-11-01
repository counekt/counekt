from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class ERC360TokenId(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	wallet_id = db.Column(db.Integer, db.ForeignKey('wallet.id', ondelete='CASCADE'))
	wallet = db.relationship("Wallet", foreign_keys=[wallet_id], backref="erc360_token_ids")
	
	amount = db.Column(db.Integer) # Amount

	""" Representation as Big Integers will likely run out year 2262, Fri on Apr 11 """
	MAX_INT = 9223372036854775807
	
	# Used for representation in accordance to reality
	creation_timestamp = db.Column(db.BigInteger) # ETH Block push timestamp
	expiration_timestamp = db.Column(db.BigInteger, default=MAX_INT)

	# Used for representation in accordance to the contract machinery
	token_id = db.Column(db.BigInteger) # Clock push time and identity
	expiration_clock = db.Column(db.BigInteger, default=MAX_INT) # Token Id Clock expiration time

	@hybrid_property
	def share(self):
		return self.amount/self.erc360.total_supply

	@property
	def percentage(self):
		return "{:g}%".format(self.share*100)

	@hybrid_property
	def is_expired(self):
		return self.expiration_clock != self.MAX_INT

	def expire(self,clock):
		self.expiration_clock = min(clock,self.MAX_INT)


	def __repr__(self):
		return '<ERC360TokenId {}>'.format(self.token_id)

