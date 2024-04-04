from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy import union_all
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy.ext.declarative import declared_attr

bank_token_amounts = db.Table('bank_token_amounts',
                  db.Column('bank_id', db.Integer, db.ForeignKey('bank.id')),
                  db.Column('token_amount_id', db.Integer, db.ForeignKey('token_amount.id'))
                  )

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	name = db.Column(db.String) # name of bank

	permit_id = db.Column(db.Integer, db.ForeignKey('permit.id'))
	permit = db.relationship("Permit",foreign_keys=[permit_id])


	token_amounts = db.relationship('TokenAmount', secondary=bank_token_amounts, lazy='dynamic')

	def __init__(self,**kwargs):
		super(Bank, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.register_token(address="0x0000000000000000000000000000000000000000",symbol="ETH",name="Ether")

	@classmethod
	def get_or_register(cls,erc360,permit_bytes):
		permit = models.Permit.get_or_register(erc360=erc360,permit_bytes=permit_bytes)
		bank = cls.query.filter(cls.erc360==erc360,cls.permit==permit).first()
		if not bank:
		    bank = cls()
		    bank.permit = permit
		    erc360.banks.append(bank)
		return bank

	def register_token(self,address,symbol=None,name=None):
		token_amount = self.token_amounts.filter(Token.address==address,Token.id==TokenAmount.token_id).first()
		if not token_amount:
			token = Token.get_or_register(address=address,symbol=symbol,name=name)
			token_amount = TokenAmount()
			token_amount.token = token
			self.token_amounts.append(token_amount)
		return token_amount


	def add_amount(self,amount,token):
		TokenAmount.get_or_register_at_bank(self,token).amount += amount

	def subtract_amount(self,amount,token):
		self.add_amount(-amount,token)

	@property
	def representation(self):
		return self.name or self.permit.bytes.hex()

	def __repr__(self):
		return '<Bank {}>'.format(self.name)

class TokenAmount(db.Model,Base):

	id = db.Column(db.Integer, primary_key=True)

	amount = db.Column(db.Numeric(precision=78), default=0) # value of token

	@declared_attr
	def token_id(self):
		return db.Column(db.Integer, db.ForeignKey('token.id', ondelete='CASCADE'))
	
	@declared_attr
	def token(self):
		return db.relationship("Token",foreign_keys=[self.token_id])

	@classmethod
	def get_or_register_at_bank(cls,bank,token,symbol=None,name=None):
		token_amount = cls.query.filter(cls.bank==bank,Token.address==token,Token.id==cls.token_id).first()
		if not token_amount:
			token = Token.get_or_register(address=token,symbol=symbol,name=name)
			token_amount = cls()
			token_amount.token = token
			bank.token_amounts.append(token_amount)
		return token_amount

	def __init__(self,**kwargs):
		super(TokenAmount, self).__init__(**{k: kwargs[k] for k in kwargs})
		# do custom initialization here
		db.session.add(self)
		self.amount = 0

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

	@property
	def pretty_html_representation(self):
		return Markup(f'<a href="{self.etherscan_url}" target="_blank">{self.representation}</a>')
		
	def __repr__(self):
		return '<Token: {} ({})>'.format(self.name, self.symbol)