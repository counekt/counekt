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
        master_role = Role(title="Master", permissionToReceiveNotifications=True,permissionToAnswerInvite=True,permissionToRejectPeople=True,permissionToCreateRoles=True,permissionToChangePeopleRoles=True,permissionToEditPage=True,permissionToCreatePrivatePosts=True,permissionToCreatePublicPosts=True)
        self.roles.append(master_role)
        for user in members:
            self.add_member(user, role=master_role)

    def add_member(self, user, role=None):
        membership = Membership()
        membership.role = role
        user.memberships.append(membership)
        self.memberships.append(membership)

    def member_has_role(self, member, role_title):
        if member in self.members:
            membership = self.memberships.filter_by(owner=member).first()
            return membership.role.title == role_title
        return False
    def member_change_role(self, member, role):
        if member in self.members:
            membership = self.memberships.filter_by(owner=member).first()
            membership.role = role

    def member_has_permission(self, member, permission):
        if member in self.members:
            membership = self.memberships.filter_by(owner=member).first()
            return getattr(membership.role,permission) == True
        return False

    def members_with_permission(self, permission):
        return [mship.owner for mship in self.memberships if getattr(mship.role,permission) == True]

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


