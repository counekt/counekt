from app import db, etherscan
from app.models.base import Base
import app.models as models
from sqlalchemy import desc, TIMESTAMP, func, select
from datetime import datetime
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from markupsafe import Markup

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
        'User', secondary=spenders, backref=db.backref("wallets",lazy='dynamic'), lazy='dynamic') 

    permits = db.relationship(
        'Permit', secondary=_permits, backref=db.backref("wallets",lazy='dynamic'), lazy='dynamic',cascade="all, delete") 

    @classmethod
    def get_or_register(cls,address,spender=None):
        wallet = cls.query.filter(cls.address==address).first()
        if not wallet:
            wallet = cls(address=address)
        if spender and not spender in wallet.spenders:
            wallet.spenders.append(spender)
        return wallet

    @hybrid_method
    def has_permit(self, erc360, hex):
        permit = erc360.permits.filter_by(bytes=bytes.fromhex(hex)).first()
        return erc360.permits.filter(permit.is_self_inclusive_descendant_of(models.Permit)).first() != None if permit else False

    @hybrid_method
    def is_permit_admin(self,erc360,hex):
        permit = erc360.permits.filter_by(bytes=bytes.fromhex(hex)).first()
        return self.has_permit(erc360,permit.parent.bytes.hex())

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

    @property
    def etherscan_url(self):
        return etherscan.get_address_link(self.address)

    @property
    def representation(self):
        return f"{self.spenders[0].dname}" if self.spenders.count() == 1 else self.address

    @property
    def representation_with_addr(self):
        return f"{self.spenders[0].dname} ({self.address})" if self.spenders.count() == 1 else self.address

    @property
    def pretty_html_representation(self):
        return Markup(f'<a href="{self.etherscan_url}" target="_blank">{self.representation}</a>')

    def __repr__(self):
        return "<Wallet {}>".format(self.address)