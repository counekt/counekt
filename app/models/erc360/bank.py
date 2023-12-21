from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy import union_all
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy.ext.declarative import declared_attr

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	name = db.Column(db.String) # name of bank

	permit_id = db.Column(db.Integer, db.ForeignKey('permit.id'))
	permit = db.relationship("Permit",foreign_keys=[permit_id])

	token_amounts = db.relationship(
        'BankTokenAmount', lazy='dynamic',
        foreign_keys='BankTokenAmount.bank_id', passive_deletes=True, cascade="all, delete")

	def __init__(self,**kwargs):
		super(Bank, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.register_token(address="0x0000000000000000000000000000000000000000",symbol="ETH",name="Ether")

	def get_token_amount(self,address):
		return self.token_amounts.filter(Token.address==address,Token.id==TokenAmount.token_id).first()

	def register_token(self,address,symbol=None,name=None):
		TOKEN = Token.register(address=address,symbol=symbol,name=name)
		token_amount = BankTokenAmount()
		token_amount.token = TOKEN
		if not self.token_amounts.filter(BankTokenAmount.token_id == TOKEN.id).first():
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

class TokenAmount(Base):

	id = db.Column(db.Integer, primary_key=True)

	amount = db.Column(db.Numeric(precision=78), default=0) # value of token
	
	@declared_attr
	def token_id(self):
		return db.Column(db.Integer, db.ForeignKey('token.id', ondelete='CASCADE'))
	
	@declared_attr
	def token(self):
		return db.relationship("Token",foreign_keys=[self.token_id])

	@hybrid_property
	def min_amount_in_decimals(self):
		return '0.'+'0'*(self.decimals-1)+'1' if self.decimals > 0 else '1'

	@hybrid_property
	def decimals(self):
		return self.token.decimals or 18

	@hybrid_property
	def amount_in_decimals(self):
		return self.amount/(10**self.decimals)

	@hybrid_property
	def amount_in_decimals(self):
		return self.amount/(10**self.decimals)

	@property
	def representation(self):
		return f"{self.amount_in_decimals} {self.token.symbol}" if self.token else self.amount

	def __repr__(self):
		return '<TokenAmount: {} {}>'.format(self.amount or 0,self.token.symbol if self.token else "")


class BankTokenAmount(db.Model, TokenAmount):
	bank_id = db.Column(db.Integer, db.ForeignKey('bank.id', ondelete='CASCADE'))

class Token(db.Model,Base):
	id = db.Column(db.Integer, primary_key=True)
	name = db.Column(db.String) # name of token
	symbol = db.Column(db.String) # symbol of token
	address = db.Column(db.String(42), unique=True) # ETH token address
	decimals = db.Column(db.Integer,default=18)

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