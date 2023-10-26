from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy import union_all
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	name = db.Column(db.String) # name of bank

	permit_id = db.Column(db.Integer, db.ForeignKey('permit.id'))
	permit = db.relationship("Permit",foreign_keys=[permit_id])

	token_amounts = db.relationship(
        'TokenAmount', lazy='dynamic',
        foreign_keys='TokenAmount.bank_id', passive_deletes=True, cascade="all, delete")

	def __init__(self,**kwargs):
		super(Bank, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.register_token("0x0000000000000000000000000000000000000000")

	def get_token_amount(self,address):
		return self.token_amounts.filter(Token.address==address,Token.id==TokenAmount.token_id).first()

	def register_token(self,address):
		TOKEN = Token.register(address=address)
		token_amount = TokenAmount()
		token_amount.token = TOKEN
		if not self.token_amounts.filter(TokenAmount.token_id == TOKEN.id).first():
			self.token_amounts.append(token_amount)

	def add_amount(self,amount,address):
		get_token_amount(address).amount += amount

	def subtract_amount(self,amount,address):
		self.add_amount(-amount,address)

	@property
	def representation(self):
		return self.name or self.permit.bytes.hex()

	def __repr__(self):
		return '<Bank {}>'.format(self.name)

class TokenAmount(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))
	token_id = db.Column(db.Integer, db.ForeignKey('token.id', ondelete='CASCADE'))
	token = db.relationship("Token",foreign_keys=[token_id])
	amount = db.Column(db.Numeric(precision=78), default=0) # value of token

	def amount_in_decimals(self,decimals):
		return self.amount/(10**decimals)

	@property
	def representation(self):
		return f"{self.amount_in_decimals(18)} {self.token.symbol}" if self.token else self.amount

	def __repr__(self):
		return '<TokenAmount: {} {}>'.format(self.amount or 0,self.token.symbol if self.token else "")

class Token(db.Model,Base):
	id = db.Column(db.Integer, primary_key=True)
	name = db.Column(db.String) # name of token
	symbol = db.Column(db.String) # symbol of token
	address = db.Column(db.String(42), unique=True) # ETH token address

	@property
	def etherscan_url(self):
		if self.address == "0x0000000000000000000000000000000000000000":
			return "https://etherscan.io/chart/etherprice"
		else:
			return f"https://etherscan.io/token/{self.address}"

	@classmethod
	def register(cls, address, name=None, symbol=None):
		token = cls.query.filter(cls.address==address).first()
		if not token:
			token = cls(address=address,name=name,symbol=symbol)
			db.session.add(token)
		return token

	@hybrid_property
	def is_named(self):
		return self.name and self.symbol

	@property
	def representation(self):
		return f"{self.name} ({self.symbol})" if self.is_named else self.address
	
	def __repr__(self):
		return '<Token: {} ({})>'.format(self.name, self.symbol)


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