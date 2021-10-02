from app.routes.profiles.routes import notifications
from app import db
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_property

class Group(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)

    roles = db.relationship("Role")

    memberships = db.relationship(
        'Membership', backref='group', lazy='dynamic',
        foreign_keys='Membership.group_id')

    def __init__(self, **kwargs):
        super(Group, self).__init__(**{k: kwargs[k] for k in kwargs if k != "members"})
        members = kwargs["members"]
        for user in members:
            self.add_member(user)

    def add_member(self, user, role=None):
        membership = Membership()
        membership.role = role
        user.memberships.append(membership)
        self.memberships.append(membership)

    def member_has_role(self, member, role_title):
        try:
            membership = self.memberships.any(owner=member).first()
            return membership.role.title == role_title
        except:
            return False

    def has_permission(self, member, permission):
        try:
            membership = self.memberships.any(owner=member).first()
            return membership.role.permission == True
        except:
            return False

    def member_got_permission(self, members, permission):
        membersAllowed = []
        for member in members:
            if self.has_permission(member, permission):
                membersAllowed.append(member)
        return membersAllowed

    def remove_member(self, user):
        self.memberships.filter_by(owner=user).delete()

    @hybrid_property
    def members(self):
        return [m.owner for m in self.memberships]

    def __repr__(self):
        return "<Group {}>".format(self.id)


class Role(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, index=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    group = db.relationship("Group", back_populates="roles", foreign_keys=[group_id])
    holders = db.relationship('Membership', back_populates="role")
    permissionToReceiveNotifications = db.Column(db.Boolean, default=False)
    permissionToAnswerInvite = db.Column(db.Boolean, default=False)
    permissionToRejectPeople = db.Column(db.Boolean, default=False)
    permissionToCreateRoles = db.Column(db.Boolean, default=False)
    permissionToChangePeopleRoles = db.Column(db.Boolean, default=False)
    permissionToEditPage = db.Column(db.Boolean, default=False)
    permissionToCreatePrivatePosts = db.Column(db.Boolean, default=False)
    permissionToCreatePublicPosts = db.Column(db.Boolean, default=False)

    def __repr__(self):
        return "<Role {}>".format(self.title)


class Membership(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    owner = db.relationship("User", foreign_keys=[owner_id])
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    role_id = db.Column(db.Integer, db.ForeignKey('role.id'))
    role = db.relationship("Role", foreign_keys=[role_id])

    def __repr__(self):
        return "<Membership {}>".format(self.role)


