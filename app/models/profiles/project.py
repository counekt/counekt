from app import db
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from app.models.profiles.group import Group
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.locationBase import locationBase
from flask import url_for

viewers = db.Table('project_viewers',
                    db.Column('project_id', db.Integer, db.ForeignKey('project.id', ondelete="cascade")),
                    db.Column('user_id', db.Integer, db.ForeignKey('user.id', ondelete="cascade"))
                    )

class Project(db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True)
    symbol = "£"
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    group = db.relationship("Group", foreign_keys=[group_id])
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    viewers = db.relationship(
        'User', secondary=viewers, lazy='dynamic')

    profile_photo_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    profile_photo = db.relationship("Photo", foreign_keys=[profile_photo_id])

    parent_id = db.Column(db.Integer, db.ForeignKey('project.id'))

    children = db.relationship('Project', backref=db.backref("superproject", remote_side=[id]))

    def __init__(self, **kwargs):
        super(Project, self).__init__(**{k: kwargs[k] for k in kwargs if k != "members"})
        # do custom initialization here
        members = kwargs["members"]
        self.group = Group(members=members)
        for user in members:
            user.projects.append(self)
        self.profile_photo = Photo(filename="profile_photo", path=f"static/profiles/projects/{self.handle}/", replacement="/static/images/project.jpg")

    def add_member(self, user):
        self.group.members.append(user)
        user.clubs.append(self)

    def remove_member(self, user):
        self.group.members.remove(user)
        user.clubs.remove(self)

    def delete(self):
        for m in self.group.members:
            m.clubs.remove(self)
        if self.exists_in_db:
            db.session.delete(self.group)
            db.session.delete(self)

    @property
    def href(self):
        return url_for("profiles.project", handle=self.handle)

    @hybrid_property
    def identifier(self):
        return self.handle

    def __repr__(self):
        return "<Project {}>".format(self.handle)
