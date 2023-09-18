from app import db
from app.models.base import Base
import app.models as models
from sqlalchemy import desc, TIMESTAMP, func, select
from datetime import datetime

spenders  = db.Table('spenders',
                  db.Column('spender_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('wallet_id', db.Integer, db.ForeignKey('wallet.id'))
                  )

_permits  = db.Table('permits',
                  db.Column('permit_id', db.Integer, db.ForeignKey('permit.id')),
                  db.Column('wallet_id', db.Integer, db.ForeignKey('wallet.id'))
                  )

class Wallet(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String(42)) # ETH token address

    spenders = db.relationship(
        'User', secondary=spenders, backref="wallets", lazy='dynamic', cascade='all,delete') 

    permits = db.relationship(
        'Permit', secondary=_permits, backref="wallets", lazy='dynamic', cascade='all,delete') 

    @classmethod
    def register(cls,spender,address):
        wallet = cls.query.filter(cls.address==address,cls.spenders.any(models.User.id==spender.id)).first()
        if not wallet:
            wallet = cls(address=address)
            spender.wallets.append(wallet)
        return wallet

    @property
    def erc360s_from_permits(self):
        return models.ERC360.query\
        .join(models.Permit,models.Permit.erc360_id == models.ERC360.id)\
        .join(_permits, models.Permit.id == _permits.c.permit_id)\
        .join(models.Wallet, models.Wallet.id == _permits.c.wallet_id)

    @property
    def erc360s_from_token_ids(self):
        return models.ERC360.query\
        .join(models.ERC360TokenId,models.ERC360TokenId.erc360_id == models.ERC360.id)\
        .join(models.Wallet, models.Wallet.id == models.ERC360TokenId.wallet_id)

    @property
    def erc360s(self):
        return self.erc360s_from_token_ids.union(self.erc360s_from_permits)

    def __repr__(self):
        return "<Wallet {}>".format(self.address)