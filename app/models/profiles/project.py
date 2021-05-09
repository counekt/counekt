from app import db
from app.models.profiles.group import Group
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.locationBase import locationBase


class Project(db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    group = db.relationship("Group", foreign_keys=[group_id])
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

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
        self.profile_pic = Photo(path=f"/static/profiles/projects/{self.handle}/profile_pic", replacement="/static/images/defaults/project.png")

    def __repr__(self):
        return "<Project {}>".format(self.handle)
