from app import db
import app.models as models
from app.models.base import Base

admins = db.Table('admins',
                  db.Column('admin_id', db.Integer, db.ForeignKey('wallet.id')),
                  db.Column('bank_id', db.Integer, db.ForeignKey('bank.id'))
                  )

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	name = db.Column(db.String) # name of bank
	tokens = db.relationship(
        'TokenAmount', lazy='dynamic',
        foreign_keys='TokenAmount.bank_id', passive_deletes=True)
	admins = db.relationship(
        'Wallet', secondary=admins, backref="members", lazy='dynamic', cascade='all,delete')

	def __repr__(self):
		return '<Bank {}>'.format(self.name)

class TokenAmount(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Integer) # value of dividend
