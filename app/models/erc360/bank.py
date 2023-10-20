from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy import union_all

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	name = db.Column(db.String) # name of bank

	permit_id = db.Column(db.Integer, db.ForeignKey('permit.id'))
	permit = db.relationship("Permit",foreign_keys=[permit_id])

	tokens = db.relationship(
        'TokenAmount', lazy='dynamic',
        foreign_keys='TokenAmount.bank_id', passive_deletes=True)

	def __init__(self,**kwargs):
        super(Bank, self).__init__(**{k: kwargs[k] for k in kwargs})
        # do custom initialization here
        self.register_token(bytes(20).hex())

	def register_token(self,address):
		token = TokenAmount(address)
		if not self.tokens.filter_by(address=address).first():
			self.tokens.append(token)

	def add_value(self,value,address):
		self.tokens.filter_by(address=address).value += value

	def subtract_value(self,value,address):
		self.add_value(-value,address)

	@property
	def representation(self):
		return self.name or self.permit.bytes.hex()

	def __repr__(self):
		return '<Bank {}>'.format(self.name)

class TokenAmount(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Numeric(precision=78), default=0) # value of token
	sender_address = db.Column(db.String(42)) # ETH sender address

"""
class TokenExchange(Base):
	id = db.Column(db.Integer, primary_key=True)
	token_address = db.Column(db.String(42)) # ETH token address
	value = db.Column(db.Integer, default=0) # value exchanged
	timestamp = db.Column(db.BigInteger) # ETH Block push timestamp

class ExternalTokenReceipt(db.Model, TokenExchange): # when entity receives a token
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))

class ExternalTokenTransfer(db.Model,TokenExchange): # when entity transfers a token
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	recipient_address = db.Column(db.String(42)) # ETH recipient address
	recipient_bank_name = db.Column(db.String) # name of bank

class InternalTokenExchange(db.Model,TokenExchange): # when entity moves a token internally
	recipient_bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	sender_bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	by_address = db.Column(db.String(42)) # ETH sender address

internal_receipts = db.relationship("InternalTokenExchange", lazy="dynamic", foreign_keys="InternalTokenExchange.recipient_bank_id", order_by="InternalTokenExchange.timestamp", cascade="all, delete-orphan", backref="recipient_bank", passive_deletes=True)
internal_transfers = db.relationship("InternalTokenExchange", lazy="dynamic", foreign_keys="InternalTokenExchange.sender_bank_id", order_by="InternalTokenExchange.timestamp", cascade="all, delete-orphan", backref="sender_bank", passive_deletes=True)
external_receipts = db.relationship("ExternalTokenReceipt", lazy="dynamic", foreign_keys="ExternalTokenReceipt.bank_id", order_by="ExternalTokenReceipt.timestamp", cascade="all, delete-orphan", backref="bank", passive_deletes=True)
external_transfers = db.relationship("ExternalTokenTransfer", lazy="dynamic", foreign_keys="ExternalTokenTransfer.bank_id", order_by="ExternalTokenTransfer.timestamp", cascade="all, delete-orphan", backref="bank", passive_deletes=True)

@property
def transactions(self):
	return union_all(self.internal_receipts,self.internal_transfers,self.external_receipts,self.external_transfers).subquery()
		
"""