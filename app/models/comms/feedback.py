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
	upvotes = db.relationship('FeedbackUpvote', backref='feedback', lazy='dynamic',
        foreign_keys='FeedbackUpvote.feedback_id')
	downvotes = db.relationship('FeedbackDownvote', backref='feedback', lazy='dynamic',
        foreign_keys='FeedbackDownvote.feedback_id')

	def upvote(self, voter):
		if not self.is_upvoted(voter):
			self.undownvote(voter=voter)
			self.upvotes.append(FeedbackUpvote(feedback=self,voter=voter))

	def downvote(self, voter):
		if not self.is_downvoted(voter):
			self.unupvote(voter=voter)
			self.downvotes.append(FeedbackDownvote(feedback=self,voter=voter))

	def unupvote(self, voter):
		fb_upvote = FeedbackUpvote.query.filter_by(feedback=self,voter=voter).first()
		if fb_upvote:
			self.upvotes.remove(fb_upvote)
			db.session.delete(fb_upvote)

	def undownvote(self, voter):
		fb_downvote = FeedbackDownvote.query.filter_by(feedback=self,voter=voter).first()
		if fb_downvote:
			self.downvotes.remove(fb_downvote)
			db.session.delete(fb_downvote)

	def is_upvoted(self, voter):
		return bool(FeedbackUpvote.query.filter_by(feedback=self,voter=voter).first())


	def is_downvoted(self, voter):
		return bool(FeedbackDownvote.query.filter_by(feedback=self,voter=voter).first())


class FeedbackUpvote(Vote,db.Model):
	feedback_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))

class FeedbackDownvote(Vote,db.Model):
	feedback_id = db.Column(db.Integer, db.ForeignKey('feedback.id'))