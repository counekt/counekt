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


followers = db.Table('followers',
                     db.Column('follower_id', db.Integer, db.ForeignKey('user.id')),
                     db.Column('followed_id', db.Integer, db.ForeignKey('user.id')))


class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True, unique=True)
    username = db.Column(db.String(120), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    phone_number = db.Column(db.String(15))
    password_hash = db.Column(db.String(128))
    name = db.Column(db.String(120))
    birthdate = db.Column(db.DateTime)
    gender = db.Column(db.String, default="Unknown")
    location = db.Column(db.String(120))
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    sin_rad_lat = db.Column(db.Float)
    cos_rad_lat = db.Column(db.Float)
    rad_lng = db.Column(db.Float)
    profile_pic_id = db.Column(db.Integer, db.ForeignKey('picture.id'))
    cover_pic_id = db.Column(db.Integer, db.ForeignKey('picture.id'))

    profile_pic = db.relationship("Picture", foreign_keys=[profile_pic_id])
    cover_pic = db.relationship("Picture", foreign_keys=[cover_pic_id])
    skills = db.relationship(
        'Skill', backref='owner', lazy='dynamic',
        foreign_keys='Skill.owner_id')
    followed = db.relationship(
        'User', secondary=followers,
        primaryjoin=(followers.c.follower_id == id),
        secondaryjoin=(followers.c.followed_id == id),
        backref=db.backref('followers', lazy='dynamic'), lazy='dynamic')

    def __init__(self, **kwargs):
        super(User, self).__init__(**kwargs)
        # do custom initialization here
        self.profile_pic = Picture(path=f"/static/images/profile_pics/{self.username}/", replacement=gravatar(self.email.lower()))
        self.cover_pic = Picture(path=f"/static/images/cover_pics/{self.username}/", replacement="/static/images/alps.jpg")

    @ hybrid_property
    def connections(self):
        return User.query.filter(User.followers.any(id=self.id)).filter(followers.c.followed_id == User.id)

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

class File():

    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(25))
    path = db.Column(db.String(2048))
    replacement = db.Column(db.String(2048))

    @ hybrid_property
    def is_empty(self):
        if not self.filename or not self.path:
            return True
        folder = os.path.join(app.root_path, Path(self.path))
        if os.path.exists(folder):
            return not bool(os.listdir(folder))

    def empty(self):
        if not self.is_empty:
            folder = os.path.join(app.root_path, Path(self.path), self.filename)
            for filename in os.listdir(folder):
                path = Path(os.path.join(folder, filename))
                path.unlink()

    def save(self, file_format, path=None):
        if not path:
            path = self.path
        folder = os.path.join(app.root_path, path)
        self.empty()
        filename = f"{datetime.now().strftime('%Y,%m,%d,%H,%M,%S')}.{file_format}"
        full_path = os.path.join(app.root_path, path, filename)
        Path(folder).mkdir(parents=True, exist_ok=True)
        self.filename = filename
        self.path = path
        return full_path

    @ hybrid_property
    def src(self):
        if not self.is_empty:
            folder = os.path.join(app.root_path, Path(self.path), self.filename)
            url = url_for(Path(self.path).parts[0], filename=join_parts(*Path(self.path).parts[1:], self.filename))
            return url

        return self.replacement

    @ hybrid_property
    def full_path(self):
        if not self.is_empty:
            return os.path.join(app.root_path, self.path, self.filename)

    def __repr__(self):
        return "<File {}>".format(self.filename)


class Picture(db.Model, File):

    def save(self, image, path=None):
        full_path = super().save(file_format=image.format, path=path)
        # Custom save
        image.save(full_path)
        return full_path

    def show(self):
        # For display in shell
        image = Image.open(self.full_path)
        image.show()

    def __repr__(self):
        return "<Picture {}>".format(self.filename)


def gravatar(text_to_digest, size=256):
    digest = md5(text_to_digest.encode("utf-8")).hexdigest()
    return "https://www.gravatar.com/avatar/{}?d=identicon&s={}".format(
        digest, size)
