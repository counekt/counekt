from app import db
from app.models.base import Base
from app.models.comms import Post
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json

class Feedback(db.Model, Base, Post):
	replies = db.relationship('Feedback', backref='to', lazy='dynamic',
        foreign_keys='Feedback.to_id')
	to_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))
