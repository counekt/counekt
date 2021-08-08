from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json
from sqlalchemy.ext.declarative import declared_attr
from datetime import datetime

posts = db.Table('posts',
                  db.Column('post_id', db.Integer, db.ForeignKey('post.id')),
                  db.Column('wall_id', db.Integer, db.ForeignKey('wall.id'))
                  )

class Wall(Base, db.Model):
	id = db.Column(db.Integer, primary_key=True)
	posts = db.relationship(
	    'Post', secondary=posts, backref="walls", lazy='dynamic')

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

	@hybrid_property
	def age(self):
		return datetime.utcnow() - self.creation_datetime

	@hybrid_property
	def age_in_minutes(self):
		return self.age / 60

	@hybrid_property
	def vote_count(self):
		return self.upvotes.count() + self.downvotes.count()

	@hybrid_property
	def vote_ratio(self):
		return self.upvotes.count()/self.vote_count

	@classmethod
	def hot(cls, query=None):
		query = query if query else cls.query
		return query(func.max(cls.vote_count/cls.age_in_minutes)).scalar()

	@classmethod
	def best(cls, query=None):
		query = query if query else cls.query
		return query(func.max(cls.vote_ratio)).scalar()

	@classmethod
	def new(cls, query=None):
		query = query if query else cls.query
		return query.order_by(cls.creation_datetime.desc())

	@classmethod
	def top(cls, query=None):
		query = query if query else cls.query
		return query(func.max(cls.vote_count)).scalar()

	@classmethod
	def search(cls, text, query=None):
		query = query if query else cls.query
		return query.filter(cls.title.ilike(f'%{text}%') or cls.content.ilike(f'%{text}%'))

class Vote:
	id = db.Column(db.Integer, primary_key=True)

	@declared_attr
	def voter_id(self):
		return db.Column(db.Integer, db.ForeignKey('user.id'))

	@declared_attr
	def voter(self):
		return db.relationship('User',foreign_keys=[self.voter_id])

class PostUpvote(Vote,db.Model):
	post_id = db.Column(db.Integer, db.ForeignKey('post.id'))

class PostDownvote(Vote,db.Model):
	post_id = db.Column(db.Integer, db.ForeignKey('post.id'))

class Post(Media,Base,db.Model):
	id = db.Column(db.Integer, primary_key=True)

	replies = db.relationship('Post', backref=db.backref("to", remote_side=[id]), lazy='dynamic',
        foreign_keys='Post.to_id')
	to_id = db.Column(db.Integer, db.ForeignKey('post.id'))
	upvotes = db.relationship('PostUpvote', backref='post', lazy='dynamic',
        foreign_keys='PostUpvote.post_id')
	downvotes = db.relationship('PostDownvote', backref='post', lazy='dynamic',
        foreign_keys='PostDownvote.post_id')
