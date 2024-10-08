from flask import current_app
from app import db
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
import app.models as models
from app.models.base import Base


associates = db.Table('associates',
                  db.Column('left_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('right_id', db.Integer, db.ForeignKey('user.id'))
                  )

followers = db.Table('followers',
                     db.Column('follower_id', db.Integer, db.ForeignKey('user.id')),
                     db.Column('followed_id', db.Integer, db.ForeignKey('user.id')))


class User(UserMixin, db.Model, Base):

    @classmethod
    @property 
    def total_associate_count(cls):
        return db.session.query(func.count()).select_from(associates).scalar()

    id = db.Column(db.Integer, primary_key=True) # DELETE THIS IN FUTURE
    creation_datetime = db.Column(db.DateTime, index=True)
    auth_token = db.Column(db.String(32), index=True, unique=True)
    auth_token_expiration = db.Column(db.DateTime)
    username = db.Column(db.String(120), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    is_activated = db.Column(db.Boolean, default=False)
    phone_number = db.Column(db.String(15))
    password_hash = db.Column(db.String(128))
    name = db.Column(db.String(120))
    bio = db.Column(db.String(160))
    birthdate = db.Column(db.DateTime)
    sex = db.Column(db.String, default="Unspecified")

    photo_id = db.Column(db.Integer, db.ForeignKey('file.id'))

    photo = db.relationship("Photo", foreign_keys=[photo_id])

    main_wallet_id = db.Column(db.Integer, db.ForeignKey('wallet.id'))
    _main_wallet = db.relationship("Wallet", foreign_keys=[main_wallet_id])

    location_id = db.Column(db.Integer, db.ForeignKey('location.id'))
    location = db.relationship("Location", foreign_keys=[location_id])

    skills = db.relationship(
        'Skill', backref='owner', lazy='dynamic',
        foreign_keys='Skill.owner_id')
    
    followed = db.relationship(
        'User', secondary=followers,
        primaryjoin=(followers.c.follower_id == id),
        secondaryjoin=(followers.c.followed_id == id),
        backref=db.backref('followers', lazy='dynamic'), lazy='dynamic')

    associates = db.relationship(
        'User', secondary=associates,
        primaryjoin=(associates.c.left_id == id),
        secondaryjoin=(associates.c.right_id == id), lazy='dynamic')

    notifications = db.relationship('Notification', back_populates='receiver',
                                    lazy='dynamic', foreign_keys='Notification.receiver_id')

    @property
    def main_wallet(self):
        return self._main_wallet or self.wallets.first()

    def __init__(self, **kwargs):
        super(User, self).__init__(**kwargs)
        # do custom initialization here
        self.creation_datetime = datetime.utcnow()
        self.photo = models.Photo(path=f"static/profile/{self.username}/photo/", replacement=self.gravatar)
        self.location = models.Location()

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def set_birthdate(self, birthdate):
        self.birthdate = birthdate
        return birthdate

    def set_location(self, location):
        self.location.set(location)

    def register_wallet(self,address):
        wallet = models.Wallet.query.filter_by(address=address).first()
        if not wallet:
            wallet = models.Wallet(address=address)
        if self.wallets.count() == 0:
            self.main_wallet = wallet
        if not self in wallet.spenders:
                wallet.spenders.append(self)

    def add_skill(self, title):
        if not self.skills.filter_by(title=title).first():
            skill = models.Skill(owner=self, title=title)
            db.session.add(skill)
            return title

    def has_skill(self, title):
        return self.has_skills([title])

    def has_skills(self, titles):
        return all([title in [skill.title for skill in self.skills.all()] for title in titles])

    def has_wallet_with_permit(self, erc360, hex):
        return self.wallets.filter(models.Wallet.has_permit(erc360,hex)).first() != None

    @property
    def amount_of_wallets(self):
        return len(self.wallets)

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

    def get_auth_token(self, expires_in=600):
        now = datetime.utcnow()
        if self.auth_token and self.auth_token_expiration > now + timedelta(seconds=60):
            return self.auth_token
        self.auth_token = base64.b64encode(os.urandom(24)).decode('utf-8').replace('/', '')
        self.auth_token_expiration = now + timedelta(seconds=expires_in)
        db.session.add(self)
        return self.auth_token

    def refresh_auth_token(self, expires_in=600):
        now = datetime.utcnow()
        self.auth_token_expiration = now + timedelta(seconds=expires_in)
        return self.auth_token

    def revoke_auth_token(self):
        now = datetime.utcnow()
        self.auth_token_expiration = now

    @staticmethod
    def check_auth_token(auth_token):
        user = User.query.filter_by(auth_token=auth_token).first()
        print(f"User is {user} and auth token expired {user.auth_token_is_expired}")
        if user is None or user.auth_token_is_expired:
            return None
        return user

    @hybrid_property
    def auth_token_is_expired(self):
        if self.auth_token_expiration:
            return self.auth_token_expiration < datetime.utcnow()
        return True

    def __repr__(self):
        return '<User {}>'.format(self.username)

    @classmethod
    def get_explore_query(cls, latitude, longitude, radius, skill=None, sex=None, min_age=None, max_age=None):
        query = cls.query.join(models.Location).filter(models.Location.is_in_explore_query(latitude, longitude, radius))

        if skill:
            query = query.filter(cls.skills.any(models.Skill.title == skill))

        if sex:
            query = query.filter(User.sex==sex)

        if min_age:
            query = query.filter(cls.is_older_than(int(min_age)))

        if max_age:
            query = query.filter(cls.is_younger_than(int(max_age)))
            
        return query

    @property
    def skillrows(self):
        return [self.skills.all()[i:i + 3] for i in range(0, len(self.skills.all()), 3)]

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
        return url_for("profile.user", username=self.username)

    @hybrid_property
    def identifier(self):
        return self.username

    def get_associates_from_text(self, text, already_chosen=None):
        query = self.associates.filter(func.lower(User.name).like(f'%{text.lower()}%'))
        if already_chosen:
            for username in already_chosen:
                query = query.filter(User.username != username)
        return query


@ login.user_loader
def load(id):
    return User.query.get(int(id))
