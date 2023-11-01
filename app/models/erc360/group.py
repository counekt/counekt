from app import db
from app.models.base import Base
import app.models.erc360.erc360 as _erc360
from sqlalchemy.ext.hybrid import hybrid_property

class Group(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)

    memberships = db.relationship(
        'Membership', backref='group', lazy='dynamic',
        foreign_keys='Membership.group_id', cascade='all,delete')

    def __init__(self, **kwargs):
        super(Group, self).__init__(**{k: kwargs[k] for k in kwargs if k != "members"})
        members = kwargs["members"]
        for user in members:
            self.add_member(user)

    def add_member(self, user):
        membership = Membership()
        user.memberships.append(membership)
        self.memberships.append(membership)

    def remove_member(self, user):
        self.memberships.filter_by(owner=user).delete()

    @hybrid_property
    def members(self):
        return [m.owner for m in self.memberships]

    @property
    def organization(self):
        return _erc360.ERC360.query.filter_by(group=self).first_or_404()

    def __repr__(self):
        return "<Group {}>".format(self.organization.handle)


class Membership(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))

    @property
    def organization(self):
        return _erc360.ERC360.query.filter_by(group=self.group).first()

    def __repr__(self):
        return "<Membership {}>".format(self.organization.handle)


