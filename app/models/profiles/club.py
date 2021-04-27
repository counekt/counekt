from app import db
from app.models.profiles.group import Group
from app.models.static.photo import Photo
from app.models.base import Base
from app.models.locationBase import locationBase
import app.funcs as funcs


class Club(db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True, unique=True)
    handle = db.Column(db.String, index=True, unique=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    group = db.relationship("Group", foreign_keys=[group_id])
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    profile_pic_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    profile_pic = db.relationship("Photo", foreign_keys=[profile_pic_id])

    def __init__(self, **kwargs):
        super(Club, self).__init__(**kwargs)
        # do custom initialization here
        members = kwargs.get(members) or []
        self.group = Group(members=members)
        for user in members:
            user.clubs.append(self)
        self.profile_pic = Photo(path=f"/static/profiles/clubs/{self.handle}/profile_pic", replacement="/static/images/defaults/club.jpg")

    def __repr__(self):
        return "<Club {}>".format(self.handle)
