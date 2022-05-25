from flask import current_app
from app import db
from app.models.base import Base
from app.models.comms.wall import Wall
from app.models.locationBase import locationBase
from app.models.static.photo import Photo
from app.models.profiles.group import Membership, Group
from app.models.profiles.club import Club
from app.models.profiles.project import Project
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy import func, inspect
from datetime import date, datetime, timedelta
import app.funcs as funcs
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from flask import url_for
import math
from hashlib import md5
import base64
from app import login
import os

convos = db.Table('convos',
                  db.Column('convo_id', db.Integer, db.ForeignKey('convo.id')),
                  db.Column('user_id', db.Integer, db.ForeignKey('user.id'))
                  )

allies = db.Table('allies',
                  db.Column('left_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('right_id', db.Integer, db.ForeignKey('user.id'))
                  )

followers = db.Table('followers',
                     db.Column('follower_id', db.Integer, db.ForeignKey('user.id')),
                     db.Column('followed_id', db.Integer, db.ForeignKey('user.id')))

clubs = db.Table('clubs',
                 db.Column('user_id', db.Integer, db.ForeignKey('user.id')),
                 db.Column('club_id', db.Integer, db.ForeignKey('club.id'))
                 )

projects = db.Table('projects',
                    db.Column('user_id', db.Integer, db.ForeignKey('user.id')),
                    db.Column('project_id', db.Integer, db.ForeignKey('project.id'))
                    )


class User(UserMixin, db.Model, Base, locationBase):
    id = db.Column(db.Integer, primary_key=True, unique=True)
    creation_datetime = db.Column(db.DateTime, index=True)
    token = db.Column(db.String(32), index=True, unique=True)
    token_expiration = db.Column(db.DateTime)
    username = db.Column(db.String(120), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    is_activated = db.Column(db.Boolean, default=False)
    phone_number = db.Column(db.String(15))
    password_hash = db.Column(db.String(128))
    name = db.Column(db.String(120))
    bio = db.Column(db.String(160))
    birthdate = db.Column(db.DateTime)
    gender = db.Column(db.String, default="Unspecified")

    profile_photo_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    cover_photo_id = db.Column(db.Integer, db.ForeignKey('photo.id'))

    profile_photo = db.relationship("Photo", foreign_keys=[profile_photo_id])
    cover_photo = db.relationship("Photo", foreign_keys=[cover_photo_id])
    skills = db.relationship(
        'Skill', backref='owner', lazy='dynamic',
        foreign_keys='Skill.owner_id')
    followed = db.relationship(
        'User', secondary=followers,
        primaryjoin=(followers.c.follower_id == id),
        secondaryjoin=(followers.c.followed_id == id),
        backref=db.backref('followers', lazy='dynamic'), lazy='dynamic')

    allies = db.relationship(
        'User', secondary=allies,
        primaryjoin=(allies.c.left_id == id),
        secondaryjoin=(allies.c.right_id == id), lazy='dynamic')

    notifications = db.relationship('Notification', back_populates='receiver',
                                    lazy='dynamic', foreign_keys='Notification.receiver_id')

    wall_id = db.Column(db.Integer, db.ForeignKey('wall.id'))
    wall = db.relationship("Wall", foreign_keys=[wall_id])

    memberships = db.relationship(
        'Membership', lazy='dynamic',
        foreign_keys='Membership.owner_id')

    clubs = db.relationship(
        'Club', secondary=clubs, backref="members", lazy='dynamic')

    projects = db.relationship(
        'Project', secondary=projects, backref="members", lazy='dynamic')
    
    convos = db.relationship(
        'Convo', secondary=convos, backref="members", lazy='dynamic')

    def __init__(self, **kwargs):
        super(User, self).__init__(**kwargs)
        # do custom initialization here
        self.creation_datetime = datetime.utcnow()
        self.profile_photo = Photo(path=f"static/profiles/users/{self.username}/profile_photo/", replacement=self.gravatar)
        self.cover_photo = Photo(path=f"static/profiles/users/{self.username}/cover_photo/", replacement="/static/images/alps.jpg")
        self.wall = Wall()

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def set_birthdate(self, birthdate):
        self.birthdate = birthdate
        return birthdate

    def add_skill(self, title):
        if not self.skills.filter_by(title=title).first():
            skill = Skill(owner=self, title=title)
            db.session.add(skill)
            return title

    def has_skill(self, title):
        return any([skill.title == title for skill in self.skills.all()])

    def has_skills(self, titles):
        return all([title in [skill.title for skill in self.skills.all()] for title in titles])

    @property
    def dname(self):
        return self.name or self.username

    @ property
    def age(self):
        return funcs.get_age(self.birthdate)

    @ hybrid_method
    def is_older_than(self, age):
        return funcs.is_older_than(self.birthdate, age)

    @ hybrid_method
    def is_younger_than(self, age):
        return funcs.is_younger_than(self.birthdate, age)

    @ hybrid_method
    def is_nearby(self, latitude, longitude, radius):
        sin_rad_lat = math.sin(math.pi * latitude / 180)
        cos_rad_lat = math.cos(math.pi * latitude / 180)
        rad_lng = math.pi * longitude / 180
        return func.acos(self.cos_rad_lat
                         * cos_rad_lat
                         * func.cos(self.rad_lng - rad_lng)
                         + self.sin_rad_lat
                         * sin_rad_lat
                         ) * 6371 <= radius

    def get_token(self, expires_in=600):
        now = datetime.utcnow()
        if self.token and self.token_expiration > now + timedelta(seconds=60):
            return self.token
        self.token = base64.b64encode(os.urandom(24)).decode('utf-8').replace('/', '')
        self.token_expiration = now + timedelta(seconds=expires_in)
        db.session.add(self)
        return self.token

    def refresh_token(self, expires_in=600):
        now = datetime.utcnow()
        self.token_expiration = now + timedelta(seconds=expires_in)
        return self.token

    def revoke_token(self):
        now = datetime.utcnow()
        self.token_expiration = now

    @staticmethod
    def check_token(token):
        user = User.query.filter_by(token=token).first()
        if user is None or user.token_is_expired:
            return None
        return user

    @hybrid_property
    def token_is_expired(self):
        if self.token_expiration:
            return self.token_expiration < datetime.utcnow()
        return True

    def __repr__(self):
        return '<User {}>'.format(self.username)

    @classmethod
    def get_explore_query(cls, latitude, longitude, radius, skill=None, gender=None, min_age=None, max_age=None):
        query = cls.query.filter(cls.is_nearby(latitude=float(latitude), longitude=float(longitude), radius=float(radius)))
        query = query.filter(cls.show_location == True, cls.is_visible == True)
        if skill:
            query = query.filter(cls.skills.any(Skill.title == skill))

        if gender:
            query = query.filter_by(gender=gender)

        if min_age:
            query = query.filter(cls.is_older_than(int(min_age)))

        if max_age:
            query = query.filter(cls.is_younger_than(int(max_age)))
        return query

    @property
    def gravatar(self, size=256):
        digest = md5(self.email.lower().encode("utf-8")).hexdigest()
        return "https://www.gravatar.com/avatar/{}?d=identicon&s={}".format(
            digest, size)

    @property
    def symbol(self):
        return "@"

    @property
    def href(self):
        return url_for("profiles.user", username=self.username)

    @hybrid_property
    def identifier(self):
        return self.username

    def get_allies_from_text(self, text, already_chosen=None):
        query = self.allies.filter(func.lower(User.name).like(f'%{text.lower()}%'))
        if already_chosen:
            for username in already_chosen:
                query = query.filter(User.username != username)
        return query


@ login.user_loader
def load(id):
    return User.query.get(int(id))
