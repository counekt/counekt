from app import db
from app.models.base import Base
import app.models as models

spenders  = db.Table('spenders',
                  db.Column('spender_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('wallet_id', db.Integer, db.ForeignKey('wallet.id'))
                  )

class Wallet(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    address = db.Column(db.String(42)) # ETH address
    spenders = db.relationship(
        'User', secondary=spenders, backref="wallets", lazy='dynamic', cascade='all,delete')

    @property
    def main_spender(self):
        return self.spenders.order_by(models.User.id.desc()).first()

    def __repr__(self):
        return "<Wallet {}>".format(self.address)
