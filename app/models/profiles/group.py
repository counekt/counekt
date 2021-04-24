from app import db
from app.models.base import Base


class Group(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)

    roles = db.relationship("Role")

    memberships = db.relationship(
        'Membership', backref='group', lazy='dynamic',
        foreign_keys='Membership.group_id')

    def __repr__(self):
        return "<Group {}>".format(self.id)


class Role(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, index=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    group = db.relationship("Group", back_populates="roles", foreign_keys=[group_id])
    holders = db.relationship('Membership', back_populates="role")

    def __repr__(self):
        return "<Role {}>".format(self.title)


class Membership(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    role_id = db.Column(db.Integer, db.ForeignKey('role.id'))
    role = db.relationship("Role", foreign_keys=[role_id])

    def __repr__(self):
        return "<Membership {}>".format(self.role)
