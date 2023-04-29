from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy import func
import json
from datetime import datetime
from flask_login import current_user

class Conversation(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    activated = db.Column(db.Boolean, default=False)

    messages = db.relationship(
        'Message', backref='conversation', lazy='dynamic',
        foreign_keys='Message.conversation_id', cascade='all,delete')
    
    @classmethod
    def get_dialogue(cls, u1, u2):
        # Get the dialogue between current_user and user if it exists
        return cls.query.join(cls.members).group_by(cls.id).having(func.count()==2).filter(cls.members.contains(u1), cls.members.contains(u2)).first()

    def get_latest_messages_by_latest_id(self, latest_id):
        if latest_id:
            latest_message = Message.query.get(latest_id)
            return self.messages.filter(Message.creation_datetime > latest_message.creation_datetime).order_by(Message.creation_datetime.asc()).all()
        return self.messages

    def __repr__(self):
        return "<Conversation>"


class Message(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    creation_datetime = db.Column(db.DateTime, index=True)
    seen = db.Column(db.Boolean, default=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    conversation_id = db.Column(db.Integer, db.ForeignKey('conversation.id'))
    text = db.Column(db.Text)

    def __init__(self, **kwargs):
        super(Message, self).__init__(**kwargs)
        # do custom initialization here
        self.creation_datetime = datetime.utcnow()

    def get_json_info(self):
        sender = "current_user" if self.sender.username == current_user.username else "user"
        return {"text":self.text, \
        "datetime":self.creation_datetime.strftime("%b %d %Y  %I:%M %p"),\
         "id":self.id,\
          "dname":self.sender.dname,\
          'href':self.sender.href, 'sender':sender}
    def __repr__(self):
        return "<Message {}>".format(self.convo)