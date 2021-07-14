from app import db
from app.models.base import Base
from time import time
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
import json

class Post(Base, db.Model):
	id = db.Column(db.Integer, primary_key=True)
	author_id = db.Column(db.Integer, db.ForeignKey('user.id'))
	creation_datetime = db.Column(db.DateTime, index=True)
	title = db.Column(db.String)
	content = db.Column(db.Text)
	upvotes = db.relationship('User')
	downvotes = db.relationship('User')
	replies = db.relationship('Post', backref='to', lazy='dynamic',
        foreign_keys='Post.to_id')
	to_id = db.Column(db.Integer, db.ForeignKey('post.id'))
