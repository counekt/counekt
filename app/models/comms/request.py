from app import db
from app.models.comms.notification import Notification
from app.models.base import Base
import json
from sqlalchemy.ext.declarative import declared_attr


class RequestBase:
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String, index=True)

    @declared_attr
    def notification_id(self):
        return db.Column(db.Integer, db.ForeignKey('notification.id'))

    @declared_attr
    def notification(self):
        return db.relationship("Notification", foreign_keys=[self.notification_id])

    def __init__(self, **kwargs):
        super(self.__class__, self).__init__(**kwargs)
        # do custom initialization here
        print(self)
        self.sender = kwargs["sender"]
        self.receiver = kwargs["receiver"]
        self.notification = Notification(receiver=self.receiver, payload_json=json.dumps(self.get_notification_payload_json()))

    def accept(self):
        self._do()
        if self.exists_in_db:
            db.session.delete(self)

    def reject(self):
        if self.exists_in_db:
            db.session.delete(self)

    def regret(self):
        if self.exists_in_db:
            db.session.delete(self)
        if self.notification.exists_in_db:
            db.session.delete(self.notification)

    def _do(self):
        # Define
        pass

    def __repr__(self):
        return "<Request {}>".format(self.type)

    def get_notification_payload_json(self):
        # Define
        return {}.get(self.type)


# From user
# --------------------------------------

class UserToUserRequest(db.Model, RequestBase, Base):
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "ally":
            self.receiver.allies.append(self.sender)
            self.sender.allies.append(self.receiver)

    def __repr__(self):
        return "<UserToUserRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"ally": {"title": "Ally request", "color": "#3298dc",
                         "icon": "fa fa-user-friends",
                         "sender-name": self.sender.name,
                         "sender-username": self.sender.username,
                         "message": "wants to ally with you",
                         "sender-photo": self.sender.profile_photo.src,
                         }}.get(self.type)


class UserToClubRequest(db.Model, RequestBase, Base):
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('club.id', ondelete='CASCADE'))
    receiver = db.relationship("Club", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "join":
            self.receiver.group.add_member(self.sender)
            self.sender.clubs.append(self.receiver)

    def __repr__(self):
        return "<UserToClubRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"join": {"color": "#3298dc",
                         "icon": "fa fa-user-friends",
                         "sender-name": self.sender.name,
                         "sender-username": self.sender.username,
                         "message": "wants to join your Club",
                         "sender-photo": self.sender.profile_photo.src,
                         }}.get(self.type)


class UserToProjectRequest(db.Model, RequestBase, Base):
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('project.id', ondelete='CASCADE'))
    receiver = db.relationship("Project", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "join":
            self.receiver.group.add_member(self.sender)
            self.sender.projects.append(self.receiver)

    def __repr__(self):
        return "<UserToProjectRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"join": {"color": "#3298dc",
                         "icon": "fa fa-user-friends",
                         "sender-name": self.sender.name,
                         "sender-username": self.sender.username,
                         "message": "wants to join your Project",
                         "sender-photo": self.sender.profile_photo.src,
                         }}.get(self.type)

# To user
# --------------------------------------


class ProjectToUserRequest(db.Model, RequestBase, Base):
    sender_id = db.Column(db.Integer, db.ForeignKey('club.id', ondelete='CASCADE'))
    sender = db.relationship("Club", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "invite":
            self.sender.group.add_member(self.receiver)
            self.receiver.projects.append(self.sender)

    def __repr__(self):
        return "<UserToClubRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"invite": {"color": "#3298dc",
                           "icon": "fa fa-user-friends",
                           "sender-name": self.sender.name,
                           "sender-handle": self.sender.handle,
                           "message": "wants you to join their Project",
                           "sender-photo": self.sender.profile_photo.src,
                           }}.get(self.type)


class ClubToUserRequest(db.Model, RequestBase, Base):
    sender_id = db.Column(db.Integer, db.ForeignKey('club.id', ondelete='CASCADE'))
    sender = db.relationship("Club", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "invite":
            self.sender.group.add_member(self.receiver)
            self.receiver.clubs.append(self.sender)

    def __repr__(self):
        return "<UserToClubRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"invite": {"color": "#3298dc",
                           "icon": "fa fa-user-friends",
                           "sender-name": self.sender.name,
                           "sender-handle": self.sender.handle,
                           "message": "wants you to join their Club",
                           "sender-photo": self.sender.profile_photo.src,
                           }}.get(self.type)
