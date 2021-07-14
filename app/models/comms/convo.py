from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json


class Convo(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)

    messages = db.relationship(
        'Message', backref='convo', lazy='dynamic',
        foreign_keys='Message.convo_id')

    @hybrid_property
    def member_count(self):
        return self.members.count()

    def __repr__(self):
        return "<Convo>"


class Message(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    seen = db.Column(db.Boolean, default=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    sender = db.relationship("User", foreign_keys=[sender_id])
    convo_id = db.Column(db.Integer, db.ForeignKey('convo.id'))

    def __repr__(self):
        return "<Message {}>".format(self.convo)