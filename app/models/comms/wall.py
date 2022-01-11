from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy import or_
from datetime import datetime
from sqlalchemy import func, inspect, case, extract
import app.funcs as funcs

media = db.Table('media',
                  db.Column('medium_id', db.Integer, db.ForeignKey('medium.id')),
                  db.Column('wall_id', db.Integer, db.ForeignKey('wall.id'))
                  )

class Wall(Base, db.Model):
	id = db.Column(db.Integer, primary_key=True)
	media = db.relationship(
	    'Medium', secondary=media, backref="walls", lazy='dynamic')

	def append(self, medium):
		self.media.append(medium)
		return medium

class Media:

	def __init__(self, **kwargs):
		super(Media, self).__init__(**kwargs)
		self.creation_datetime = datetime.utcnow()
	
	@declared_attr
	def author_id(self):
		return db.Column(db.Integer, db.ForeignKey('user.id'))

	@declared_attr
	def author(self):
		return db.relationship('User',foreign_keys=[self.author_id])

	creation_datetime = db.Column(db.DateTime, index=True)
	title = db.Column(db.String)
	content = db.Column(db.Text)
	public = db.Column(db.Boolean, default=False)

	def upvote(self, voter):
		if not self.is_upvoted(voter):
			self.undownvote(voter=voter)
			self.upvotes.append(self.upvote_class(media=self,voter=voter))

	def downvote(self, voter):
		if not self.is_downvoted(voter):
			self.unupvote(voter=voter)
			self.downvotes.append(self.downvote_class(media=self,voter=voter))

	def unupvote(self, voter):
		upvote_ = self.upvote_class.query.filter_by(media=self,voter=voter).first()
		if upvote_:
			self.upvotes.remove(upvote_)
			db.session.delete(upvote_)

	def undownvote(self, voter):
		downvote_ = self.downvote_class.query.filter_by(media=self,voter=voter).first()
		if downvote_:
			self.downvotes.remove(downvote_)
			db.session.delete(downvote_)

	def is_upvoted(self, voter):
		return bool(self.upvote_class.query.filter_by(media=self,voter=voter).first())


	def is_downvoted(self, voter):
		return bool(self.downvote_class.query.filter_by(media=self,voter=voter).first())

	@property
	def hotness(self, now=datetime.utcnow()):
		return (self.upvotes.count()+self.downvotes.count())/max(1, (now - self.creation_datetime).total_seconds()+self.upvotes.count()+self.downvotes.count())

	@hybrid_property
	def age(self):
		return datetime.utcnow() - self.creation_datetime

	@hybrid_property
	def age_in_minutes(self, now=datetime.utcnow()):
		return func.trunc(extract('epoch',now)-extract('epoch', self.creation_datetime)/60)

	@hybrid_property
	def vote_ratio(self):
		return func.count(self.upvotes)/case([(self.count_votes()>0,self.count_votes())],else_=1)

	@hybrid_method
	def count_upvotes(self):
		return func.count(self.upvotes)

	@hybrid_method
	def count_downvotes(self):
		return func.count(self.downvotes)

	@hybrid_method
	def count_votes(self):
		return self.count_upvotes() + self.count_downvotes()

	@property
	def upvote_count(self):
		return self.upvotes.count()

	@property
	def downvote_count(self):
		return self.downvotes.count()

	@classmethod
	def hot(cls, query=None):
		query = query if query else cls.query
		return query.outerjoin(cls.upvote_class, cls.downvote_class).group_by(cls.id).order_by((cls.count_votes()/case([(cls.age_in_minutes>0,cls.age_in_minutes)],else_=1)).desc())

	@classmethod
	def best(cls, query=None):
		query = query if query else cls.query
		return query.outerjoin(cls.upvote_class, cls.downvote_class).group_by(cls.id).order_by(cls.vote_ratio.desc())

	@classmethod
	def new(cls, query=None):
		query = query if query else cls.query
		return query.order_by(cls.creation_datetime.desc())

	@classmethod
	def top(cls, query=None):
		query = query if query else cls.query
		return query.outerjoin(cls.upvote_class, cls.downvote_class).group_by(cls.id).order_by((func.count(cls.upvotes)+func.count(cls.downvotes)).desc())

	@classmethod
	def search(cls, text, query=None):
		query = query if query else cls.query
		return query.filter(or_(cls.title.ilike(f'%{text}%'),cls.content.ilike(f'%{text}%')))

	@classmethod
	def search_by(cls, search, by, query=None):
		query = query if query else cls.query
		query = cls.search(search) if search else query
		return {"hot":cls.hot(query=query),"best":cls.best(query=query),"new":cls.new(query=query),"hot":cls.hot(query=query)}.get(by) or query

	@classmethod
	@property
	def upvote_class(cls):
		relationships = inspect(cls).relationships
		return relationships["upvotes"].entity.class_

	@classmethod
	@property
	def downvote_class(cls):
		relationships = inspect(cls).relationships
		return relationships["downvotes"].entity.class_
       
class Vote:
	id = db.Column(db.Integer, primary_key=True)

	@declared_attr
	def voter_id(self):
		return db.Column(db.Integer, db.ForeignKey('user.id'))

	@declared_attr
	def voter(self):
		return db.relationship('User',foreign_keys=[self.voter_id])

class MediumHeart(Vote,db.Model):
	medium_id = db.Column(db.Integer, db.ForeignKey('medium.id'))

class MediumDownvote(Vote,db.Model):
	medium_id = db.Column(db.Integer, db.ForeignKey('medium.id'))

class Medium(Media,Base,db.Model):

	def __init__(self, **kwargs):
		super(Medium, self).__init__(**kwargs)

	id = db.Column(db.Integer, primary_key=True)
	author_id = db.Column(db.Integer, db.ForeignKey('user.id'))
	author = db.relationship("User", foreign_keys=[author_id])

	quotes = db.relationship('Medium', backref=db.backref("quote_to", remote_side=[id]), lazy='dynamic',
        foreign_keys='Medium.quote_to_id')

	replies = db.relationship('Medium', backref=db.backref("reply_to", remote_side=[id]), lazy='dynamic',
        foreign_keys='Medium.reply_to_id')

	reply_to_id = db.Column(db.Integer, db.ForeignKey('medium.id'))
	quote_to_id = db.Column(db.Integer, db.ForeignKey('medium.id'))

	upvotes = db.relationship('MediumHeart', backref='media', lazy='dynamic',
        foreign_keys='MediumHeart.medium_id')
	downvotes = db.relationship('MediumDownvote', backref='media', lazy='dynamic',
        foreign_keys='MediumDownvote.medium_id')
	
	project_channel_id = db.Column(db.Integer, db.ForeignKey('project.id'))
	project_channel = db.relationship("Project", foreign_keys=[project_channel_id])
	club_channel_id = db.Column(db.Integer, db.ForeignKey('club.id'))
	club_channel = db.relationship("Club", foreign_keys=[club_channel_id])

	def is_hearted(self, voter):
		return self.is_upvoted(voter)

	def heart(self, voter):
		self.upvote(voter)

	def unheart(self, voter):
		self.unupvote(voter)

	@hybrid_property
	def count_hearts(self):
		return self.total_upvotes()

	@property
	def heart_count(self):
		return self.upvote_count

	@property
	def reply_count(self):
		return self.replies.count()

	@property
	def quote_count(self):
		return self.quotes.count()

	def channel(self):
		return self.project_channel or self.club_channel