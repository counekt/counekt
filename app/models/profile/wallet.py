from app import db
from app.models.base import Base
import app.models as models
from sqlalchemy import desc, TIMESTAMP, func, select
from datetime import datetime

spenders  = db.Table('spenders',
                  db.Column('spender_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('wallet_id', db.Integer, db.ForeignKey('wallet.id')),
                  )

class Wallet(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String(42)) # ETH token address

    spenders = db.relationship(
        'User', secondary=spenders, backref="wallets", lazy='dynamic', cascade='all,delete')

    @classmethod
    def register(cls,spender,address):
        wallet = cls.query.filter(cls.address==address,cls.spenders.any(models.User.id==spender.id)).first()
        if not wallet:
            wallet = cls(address=address)
            spender.wallets.append(wallet)
        return wallet

    def __repr__(self):
        return "<Wallet {}>".format(self.address)