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
        # Define this
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
        if self.type == "associate":
            self.receiver.associates.append(self.sender)
            self.sender.associates.append(self.receiver)

    def __repr__(self):
        return "<UserToUserRequest {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"associate": {"type": "request",
                         "request_type":"UserToUserRequest",
                         "request_subtype":"associate",
                         "color": "#3298dc",
                         "icon": "fa fa-user-friends",
                         "sender-name": self.sender.name,
                         "sender-username": self.sender.username,
                         "message": "wants to associate with you",
                         "sender-photo": self.sender.photo.src,
                         "href":f"/@{self.sender.username}/"
                         }}.get(self.type)


class UserToERC360Request(db.Model, RequestBase, Base):
    user_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    user = db.relationship("User", foreign_keys=[user_id])
    erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
    erc360 = db.relationship("ERC360", foreign_keys=[erc360_id])
    user_is_sender = db.Column(db.Boolean, index=True)


    def __init__(self, **kwargs):
        RequestBase.__init__(self, **kwargs)

    def _do(self):
        if self.type == "join":
            self.receiver.viewers.remove(self.sender)
            self.receiver.add_member(self.sender)

    def __repr__(self):
        return "<UserToERC360Request {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"dummy": {"type": "request",
                         "request_type":"UserToIdeaRequest",
                         "request_subtype":"dummy",
                         "color": "#3298dc",
                         "icon": "fa fa-user-friends",
                         "sender-name": self.sender.name,
                         "sender-username": self.sender.username,
                         "message": "some dummy text ERC360",
                         "sender-photo": self.sender.photo.src,
                         "href":f"/€{self.receiver.address}/"
                         }}.get(self.type) if user_is_sender else {"dummy": {"type": "request",
                           "request_type":"ERC360ToUserRequest",
                           "request_subtype":"invite",
                           "color": "#3298dc",
                           "icon": "fa fa-user-friends",
                           "sender-name": self.sender.name,
                           "sender-address": self.sender.address,
                           "message": "some dummy text ERC360",
                           "sender-photo": self.sender.photo.src,
                           "href":f"/€{self.sender.address}/"
                           }}.get(self.type)