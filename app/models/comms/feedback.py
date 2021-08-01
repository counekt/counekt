from app import db
from app.models.base import Base
from app.models.comms.wall import Media
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json

class Feedback(Media, Base, db.Model):

	def __init__(self, **kwargs):
		print(kwargs)
		super(Feedback, self).__init__(**kwargs)

	id = db.Column(db.Integer, primary_key=True)
	to_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))
	replies = db.relationship('Feedback', lazy='dynamic',
        remote_side=[to_id])
