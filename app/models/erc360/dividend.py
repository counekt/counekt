from app import db
import app.models as models
from app.models.base import Base
from app.models.erc360.bank import TokenAmount, Token

class Dividend(db.Model, Base):

	def __init__(self, token_address, amount, **kwargs):
		super(Dividend, self).__init__(**{k: kwargs[k] for k in kwargs})
		self.token_amount = DividendTokenAmount(token=Token.register(token_address),amount=amount)
		self.token_residual = DividendTokenAmount(token=Token.register(token_address),amount=amount)
	
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
	clock = db.Column(db.BigInteger) # clock
	event_id = db.Column(db.Integer) # event id, used for identification
	token_amount_id = db.Column(db.Integer)
	token_residual_id = db.Column(db.Integer)
	token_amount = db.relationship("DividendTokenAmount", foreign_keys=[token_amount_id])
	token_residual = db.relationship("DividendTokenAmount", foreign_keys=[token_residual_id])
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
	token_amount_id = db.Column(db.Integer)
	token_amount = db.relationship("DividendTokenAmount", foreign_keys=[token_amount_id])
	erc360_token_id_id = db.Column(db.Integer, db.ForeignKey('erc360_token_id.id', ondelete='CASCADE')) 
	erc360_token_id = db.relationship("ERC360TokenId", foreign_keys=[erc360_token_id_id]) # shard used to claim dividend

	def __repr__(self):
		return '<DividendClaim {}>'.format(self.dividend.clock)

class DividendTokenAmount(db.Model, TokenAmount):
	pass
