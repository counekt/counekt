from app import db
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from app.models.profiles.group import Group
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.locationBase import locationBase
from flask import url_for

viewers = db.Table('idea_viewers',
                    db.Column('idea_id', db.Integer, db.ForeignKey('idea.id', ondelete="cascade")),
                    db.Column('user_id', db.Integer, db.ForeignKey('user.id', ondelete="cascade"))
                    )

class Idea(db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True)
    symbol = "$"
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

    parent_id = db.Column(db.Integer, db.ForeignKey('idea.id'))

    children = db.relationship('Idea', backref=db.backref("superidea", remote_side=[id]))

    def __init__(self, **kwargs):
        super(Idea, self).__init__(**{k: kwargs[k] for k in kwargs if k != "members"})
        # do custom initialization here
        members = kwargs["members"]
        self.group = Group(members=members)
        for user in members:
            user.ideas.append(self)
        self.profile_photo = Photo(filename="profile_photo", path=f"static/profiles/ideas/{self.handle}/", replacement="/static/images/idea.jpg")

    def add_member(self, user):
        self.group.members.append(user)
        user.ideas.append(self)

    def remove_member(self, user):
        self.group.members.remove(user)
        user.ideas.remove(self)

    def delete(self):
        for m in self.group.members:
            m.ideas.remove(self)
        if self.exists_in_db:
            db.session.delete(self.group)
            db.session.delete(self)

    @property
    def href(self):
        return url_for("profiles.idea", handle=self.handle)

    @hybrid_property
    def identifier(self):
        return self.handle

    def __repr__(self):
        return "<Idea ${}>".format(self.handle)
