from app import db
from app.models.base import Base

spenders  = db.Table('spenders',
                  db.Column('spender_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('wallet_id', db.Integer, db.ForeignKey('wallet.id'))
                  )

class Wallet(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String(42)) # ETH address
    spenders = db.relationship(
        'User', secondary=spenders, backref="wallets", lazy='dynamic', cascade='all,delete')

    def __repr__(self):
        return "<Wallet {}>".format(self.address)
