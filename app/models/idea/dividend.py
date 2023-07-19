from app import db
import app.models as models
from app.models.base import Base

claimants = db.Table('claimants',
                  db.Column('claimant_id', db.Integer, db.ForeignKey('wallet.id')),
                  db.Column('dividend_id', db.Integer, db.ForeignKey('dividend.id'))
                  )

class Dividend(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	clock = db.Column(db.Integer) # clock of issuance, used to identify
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Integer) # value of dividend
	claimants = db.relationship(
        'Wallet', secondary=claimants, lazy='dynamic', cascade='all,delete')

	def __repr__(self):
		return '<Dividend {}>'.format(self.clock)