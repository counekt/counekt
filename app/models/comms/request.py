from app import db
from app.models.comms.notification import Notification
from app.models.base import Base


class Request(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String)
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])

    def __init__(self, **kwargs):
        super(Request, self).__init__(**kwargs)
        # do custom initialization here
        self.notification = Notification(payload_json=json.dumps(self.get_notification_payload_json()))

    def accept(self):
        self.__do()
        if self.exists_in_db(self):
            db.session.delete(self)

    def reject(self):
        if self.exists_in_db(self):
            db.session.delete(self)

    def regret(self):
        if self.exists_in_db(self):
            db.session.delete(self)
        if self.exists_in_db(self.notification):
            db.session.delete(self.notification)

    def __do(self):
        if self.type == "connect":
            self.receiver.connections.append(self.sender)
            self.sender.connections.append(self.receiver)

    def __repr__(self):
        return "<Request {}>".format(self.type)

    def get_notification_payload_json(self):
        return {"connect": {"color": "#3298dc",
                            "icon": "fa fa-user-friends",
                            "sender-name": self.sender.name,
                            "sender-username": self.sender.username,
                            "message": "{} wants to connect",
                            "sender-photo": self.sender.profile_photo.src,
                            }}.get(self.type)
