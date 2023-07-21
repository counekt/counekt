from app import db
import app.models as models
from app.models.base import Base

class Dividend(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	clock = db.Column(db.Integer) # clock of issuance, used to identify
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Integer) # value of dividend
	claims = db.relationship(
        'DividendClaim', lazy='dynamic',
        foreign_keys='DividendClaim.dívidend_id', passive_deletes=True)

	def __repr__(self):
		return '<Dividend {}>'.format(self.clock)

class DividendClaim(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	dividend_id = db.Column(db.Integer, db.ForeignKey('dividend.id', ondelete='CASCADE'))
	value = db.Column(db.Integer) # value of claim
	shard_id = db.Column(db.Integer) 
	shard = db.relationship("Shard", foreign_keys=[shard_id]) # shard used to claim dividend

	def __repr__(self):
		return '<DividendClaim {}>'.format(self.value)

