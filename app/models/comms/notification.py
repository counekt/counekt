from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json


class Notification(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    seen = db.Column(db.Boolean, default=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])
    timestamp = db.Column(db.Float, index=True, default=time)
    payload_json = db.Column(db.Text)

    def __init__(self, **kwargs):
        super(Notification, self).__init__(**kwargs)
        if kwargs.get("receiver"):
            receiver = kwargs.get("receiver")
            receiver.notifications.append(self)

    def __repr__(self):
        return "<Notification {}>".format(self.get_data().get('type'))

    def get_data(self):
        return json.loads(str(self.payload_json))


"""
class Notification(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String)

    timestamp = db.Column(db.Float, index=True, default=time)

    object_role_id = db.Column(db.Integer, db.ForeignKey('role.id'))
    object_group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    object_project_id = db.Column(db.Integer, db.ForeignKey('project.id'))

    object_role = db.relationship("Role", foreign_keys=[object_role_id])
    object_group = db.relationship("Group", foreign_keys=[object_group_id])
    object_project = db.relationship("Project", foreign_keys=[object_project_id])

    sender_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))

    sender = db.relationship("User", foreign_keys=[sender_id])
    receiver = db.relationship("User", foreign_keys=[receiver_id])

    request = db.relationship("Request", back_populates="notification", uselist=False)

    @hybrid_property
    def object(self):
        return self.object_group or self.object_project or self.object_role

    @hybrid_property
    def object_id(self):
        return self.object_group_id or self.object_project_id or self.object_role_id

    @property
    def raw(self):
        return {"type": self.type,
                "color": self.color,
                "icon": self.icon,
                "sender-name": self.sender.name,
                "sender-username": self.sender.username,
                "message": self.message,
                "sender-photo": self.sender.profile_photo.src,
                "object-name": getattr(self.object, 'handle', lambda: None)() or getattr(self.object, 'title', lambda: None)(),
                "object-photo": getattr(self.object, 'profile_pic', lambda: None)()}

    @property
    def color(self):
        return {"connect": "#3298dc",
                "ban": "hsl(348, 100%, 61%)",
                "invite": "#3298dc",
                "role": "#3273dc",
                "message": "#3298dc",
                "accepted-invite": "hsl(141, 53%, 53%)",
                "accepted-connect": "hsl(141, 53%, 53%)",
                "rejected-invite": "hsl(348, 100%, 61%)",
                "rejected-connect": "hsl(348, 100%, 61%)"}.get(self.type)

    @property
    def icon(self):
        return {"connect": "fa fa-user-friends",
                "ban": "fa fa-ban",
                "invite": "fa fa-envelope",
                "role": "fa fa-black-tie",
                "message": "fa fa-comments",
                "accepted-invite": "fa fa-envelope",
                "accepted-connect": "fa fa-user-friends",
                "rejected-invite": "fa fa-envelope",
                "rejected-connect": "fa fa-user-friends"}.get(self.type)

    @property
    def message(self):
        return {"connect": "wants to connect",
                "ban": "banned you from",
                "invite": "invited you to join",
                "role": "changed your role to",
                "message": "messaged you",
                "accepted-invite": "accepted your invite to",
                "accepted-connect": "accepted your attempt to connect",
                "rejected-invite": "rejected your invite to",
                "rejected-connect": "rejected your attempt to connect"}.get(self.type)

    @property
    def has_object(self):
        return {"connect": False,
                "ban": True,
                "invite": True,
                "role": True,
                "message": False,
                "accepted-invite": True,
                "accepted-connect": False,
                "rejected-invite": True,
                "rejected-connect": False}.get(self.type)

    def __repr__(self):
        return "<Notification {}>".format(self.type)
"""
