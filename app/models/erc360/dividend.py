from app import db
import app.models as models
from app.models.base import Base
from app.models.erc360.bank import TokenAmount, Token

class Dividend(db.Model, Base):

	def __init__(self, token_address, amount, **kwargs):
		super(Dividend, self).__init__(**{k: kwargs[k] for k in kwargs})
		self.token_amount = TokenAmount(token=Token.register(token_address),amount=amount)
		self.token_residual = TokenAmount(token=Token.register(token_address),amount=amount)
	
	id = db.Column(db.Integer, primary_key=True)
	clock = db.Column(db.BigInteger) # clock
	identifier = db.Column(db.Integer) # event id, used for identification
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
	initial_token_amount_id = db.Column(db.Integer, db.ForeignKey('token_amount.id'))
	residual_token_amount_id = db.Column(db.Integer, db.ForeignKey('token_amount.id'))
	initial_token_amount = db.relationship("TokenAmount", foreign_keys=[initial_token_amount_id])
	residual_token_amount = db.relationship("TokenAmount", foreign_keys=[residual_token_amount_id])
	claims = db.relationship(
        'DividendClaim', lazy='dynamic',
        foreign_keys='DividendClaim.dividend_id', passive_deletes=True, backref="dividend")

	@property
	def representation(self):
		return f"{self.clock} ({self.value})"

	def __repr__(self):
		return '<Dividend {}>'.format(self.clock)

class DividendClaim(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	dividend_id = db.Column(db.Integer, db.ForeignKey('dividend.id', ondelete='CASCADE'))
	token_amount_id = db.Column(db.Integer, db.ForeignKey('token_amount.id', ondelete='CASCADE'))
	token_amount = db.relationship("TokenAmount", foreign_keys=[token_amount_id])
	erc360_shard_id = db.Column(db.Integer, db.ForeignKey('erc360_shard.id', ondelete='CASCADE')) 
	erc360_shard = db.relationship("ERC360Shard", foreign_keys=[erc360_shard_id]) # shard used to claim dividend

	def __repr__(self):
		return '<DividendClaim {}>'.format(self.dividend.clock)