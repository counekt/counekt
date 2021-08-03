from app import db
from app.models.base import Base
from app.models.comms.wall import Media, Vote
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
	upvotes = db.relationship('FeedbackUpvote', backref='post', lazy='dynamic',
        foreign_keys='FeedbackUpvote.feedback_id')
	downvotes = db.relationship('FeedbackDownvote', backref='post', lazy='dynamic',
        foreign_keys='FeedbackDownvote.feedback_id')

class FeedbackUpvote(Vote,db.Model):
	feedback_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))

class FeedbackDownvote(Vote,db.Model):
	feedback_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))