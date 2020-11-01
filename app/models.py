from app import db, hybrid_method, hybrid_property, func
from app import login
from datetime import datetime
from app.funcs import geocode, get_age, is_older, is_younger
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from flask import url_for
import math
from hashlib import md5
from datetime import date


@login.user_loader
def load_user(id):
    return User.query.get(int(id))


class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True, unique=True)

    username = db.Column(db.String(120), index=True)
    email = db.Column(db.String(120))
    phone_number = db.Column(db.String(15))
    password_hash = db.Column(db.String(128))

    name = db.Column(db.String(120))
    birthdate = db.Column(db.DateTime)
    gender = db.Column(db.String, default="Unknown")
    skills = db.relationship(
        'Skill', backref='owner', lazy='dynamic',
        foreign_keys='Skill.owner_id')

    location = db.Column(db.String(120))
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)

    sin_rad_lat = db.Column(db.Float)
    cos_rad_lat = db.Column(db.Float)
    rad_lng = db.Column(db.Float)

    skills = db.relationship(
        'Skill', backref='owner', lazy='dynamic',
        foreign_keys='Skill.owner_id')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def set_location(self, location, prelocated=False):
        if not prelocated:
            location = geocode(location)
        if location:
            self.location = location.address
            self.latitude = location.latitude
            self.longitude = location.longitude
            self.sin_rad_lat = math.sin(math.pi * location.latitude / 180)
            self.cos_rad_lat = math.cos(math.pi * location.latitude / 180)
            self.rad_lng = math.pi * location.longitude / 180
        return location

    def set_birthdate(self, day, month, year):
        birthdate = date(day=day, month=month, year=year)
        self.birthdate = birthdate
        return birthdate

    def add_skill(self, title):
        if not self.skills.filter_by(title=title).first():
            skill = Skill(owner=self, title=title)
            db.session.add(skill)
            return title

    @ hybrid_property
    def age(self):
        return get_age(self.birthdate)

    @ hybrid_method
    def is_older_than(self, age):
        return is_older(self.birthdate, age)

    @ hybrid_method
    def is_younger_than(self, age):
        return is_younger(self.birthdate, age)

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

    def __repr__(self):
        return '<User {}>'.format(self.username)


def get_explore_query(latitude, longitude, radius, skill=None, gender=None, min_age=None, max_age=None):
    query = User.query.filter(User.is_nearby(latitude=float(latitude), longitude=float(longitude), radius=float(radius)))

    if skill:
        query = query.filter(User.skills.any(Skill.title == skill))

    if gender:
        query = query.filter_by(gender=gender)

    if min_age:
        query = query.filter(User.is_older_than(int(min_age)))

    if max_age:
        query = query.filter(User.is_younger_than(int(max_age)))
    return query


class Skill(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(20), index=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))

    def __repr__(self):
        return "<Skill {}>".format(self.title)
