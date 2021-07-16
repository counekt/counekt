from app import db
from app.models.base import Base
from app.models.comms.wall import Media
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json

class Feedback(Media, Base):
	id = db.Column(db.Integer, primary_key=True)

	replies = db.relationship('Feedback', backref='to', lazy='dynamic',
        foreign_keys='Feedback.to_id')
	to_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))
