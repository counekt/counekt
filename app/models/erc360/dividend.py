from app import db
import app.models as models
from app.models.base import Base

class Dividend(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
	clock = db.Column(db.BigInteger) # clock
	event_id = db.Column(db.Integer) # event id, used for identification
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Integer) # value of dividend
	residual = db.Column(db.Integer) # residual of dividend
	claims = db.relationship(
        'DividendClaim', lazy='dynamic',
        foreign_keys='DividendClaim.dividend_id', passive_deletes=True)

	def __repr__(self):
		return '<Dividend {}>'.format(self.clock)

class DividendClaim(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	dividend_id = db.Column(db.Integer, db.ForeignKey('dividend.id', ondelete='CASCADE'))
	value = db.Column(db.Integer) # value of claim
	erc360_token_id_id = db.Column(db.Integer, db.ForeignKey('erc360_token_id.id', ondelete='CASCADE')) 
	erc360_token_id = db.relationship("ERC360TokenId", foreign_keys=[erc360_token_id_id]) # shard used to claim dividend

	def __repr__(self):
		return '<DividendClaim {}>'.format(self.value)

