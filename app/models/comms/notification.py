from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json


class Notification(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    seen = db.Column(db.Boolean, default=False)
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    receiver = db.relationship("User", foreign_keys=[receiver_id])
    timestamp = db.Column(db.Float, index=True, default=time)
    payload_json = db.Column(db.Text)

    @property
    def type(self):
        return self.get_data().get('type')

    @property
    def request(self):
        assert self.type == "request"
        return Request.query.filter_by(notification=self).first_or_404()

    def __init__(self, **kwargs):
        super(Notification, self).__init__(**kwargs)
        if kwargs.get("receiver"):
            receiver = kwargs.get("receiver")
            receiver.notifications.append(self)

    def __repr__(self):
        return "<Notification {}>".format(self.type)

    def get_data(self):
        return json.loads(str(self.payload_json))
