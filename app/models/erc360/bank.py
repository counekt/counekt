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
        foreign_keys='BankTokenAmount.bank_id', backref="bank", passive_deletes=True, cascade="all, delete")

	def __init__(self,**kwargs):
		super(Bank, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.register_token(address="0x0000000000000000000000000000000000000000",symbol="ETH",name="Ether")

	@classmethod
	def get_or_register(cls,erc360,bytes):
		permit = models.Permit.get_or_register(erc360=erc360,bytes=bytes)
		bank = cls.query.filter(cls.erc360==erc360,cls.permit==permit).first()
		if not bank:
		    bank = cls()
		    bank.permit = permit
		    erc360.banks.append(bank)
		return bank

	def get_or_register_token_amount(self,token,symbol=None,name=None):
		token_amount = self.token_amounts.filter(Token.address==token,Token.id==BankTokenAmount.token_id).first()
		if not token_amount:
			token = Token.get_or_register(address=token,symbol=symbol,name=name)
			token_amount = BankTokenAmount()
			token_amount.token = token
			self.token_amounts.append(token_amount)
		return token_amount		


	def add_amount(self,amount,token):
		BankTokenAmount.get_or_register(self,token).amount += amount

	def subtract_amount(self,amount,token):
		self.add_amount(-amount,token)

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

	def __init__(self,**kwargs):
		super(BankTokenAmount, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.amount = 0

	@classmethod
	def get_or_register(cls,bank,token,symbol=None,name=None):
		token_amount = cls.query.filter(cls.bank==bank,Token.address==token,Token.id==cls.token_id).first()
		if not token_amount:
			token = Token.get_or_register(address=token,symbol=symbol,name=name)
			token_amount = cls()
			token_amount.token = token
			bank.token_amounts.append(token_amount)
			print(token_amount)
		return token_amount

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
	def get_or_register(cls, address, name=None, symbol=None):
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