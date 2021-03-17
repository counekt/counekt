from flask import current_app
from app import db
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy import func
from app import login
from datetime import date, datetime, timedelta
from time import time
import app.funcs as funcs
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from flask import url_for
import math
from hashlib import md5
import base64
import os
from PIL import Image
from pathlib import Path


@login.user_loader
def load_user(id):
    return User.query.get(int(id))


followers = db.Table('followers',
                     db.Column('follower_id', db.Integer, db.ForeignKey('user.id')),
                     db.Column('followed_id', db.Integer, db.ForeignKey('user.id')))

groups = db.Table('groups',
                  db.Column('user_id', db.Integer, db.ForeignKey('user.id')),
                  db.Column('group_id', db.Integer, db.ForeignKey('group.id'))
                  )

projects = db.Table('projects',
                    db.Column('user_id', db.Integer, db.ForeignKey('user.id')),
                    db.Column('project_id', db.Integer, db.ForeignKey('project.id'))
                    )


class User(UserMixin, db.Model):
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
    address = db.Column(db.String)
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    sin_rad_lat = db.Column(db.Float)
    cos_rad_lat = db.Column(db.Float)
    rad_lng = db.Column(db.Float)
    show_location = db.Column(db.Boolean, default=False)
    is_visible = db.Column(db.Boolean, default=False)
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

    notifications = db.relationship('Notification', backref='user',
                                    lazy='dynamic', foreign_keys='Notification.receiver_id')
    groups = db.relationship(
        'Group', secondary=groups,
        primaryjoin=(groups.c.user_id == id),
        secondaryjoin=(groups.c.group_id == id),
        backref=db.backref('members', lazy='dynamic'), lazy='dynamic')

    projects = db.relationship(
        'Project', secondary=projects,
        primaryjoin=(projects.c.user_id == id),
        secondaryjoin=(projects.c.project_id == id),
        backref=db.backref('members', lazy='dynamic'), lazy='dynamic')

    def __init__(self, **kwargs):
        super(User, self).__init__(**kwargs)
        # do custom initialization here
        self.creation_datetime = datetime.utcnow()
        self.profile_photo = Photo(filename="profile_photo", path=f"static/profiles/users/{self.username}/", replacement=gravatar(self.email.lower()))
        self.cover_photo = Photo(filename="cover_photo", path=f"static/profiles/users/{self.username}/", replacement="/static/images/alps.jpg")

    @ hybrid_property
    def connections(self):
        return User.query.filter(User.followers.any(id=self.id)).filter(followers.c.followed_id == User.id)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def set_location(self, location):
        if location:
            self.address = funcs.shorten_addr(location=location)
            self.latitude = location.latitude
            self.longitude = location.longitude
            self.sin_rad_lat = math.sin(math.pi * location.latitude / 180)
            self.cos_rad_lat = math.cos(math.pi * location.latitude / 180)
            self.rad_lng = math.pi * location.longitude / 180

        return location

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


def get_explore_query(latitude, longitude, radius, skill=None, gender=None, min_age=None, max_age=None):
    query = User.query.filter(User.is_nearby(latitude=float(latitude), longitude=float(longitude), radius=float(radius)))
    query = query.filter(User.show_location == True, User.is_visible == True)
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
    filename = db.Column(db.String)
    path = db.Column(db.String(2048))

    def save_locally(self, file_format):
        self.empty()
        folder = os.path.join(current_app.root_path, self.path, self.filename)
        end_filename = f"{datetime.now().strftime('%Y,%m,%d,%H,%M,%S')}.{file_format}"
        full_local_path = os.path.join(current_app.root_path, folder, end_filename)
        # make sure the whole path exists
        Path(folder).mkdir(parents=True, exist_ok=True)
        return full_local_path

    def upload_to_bucket(self):
        # Uploading to bucket
        funcs.upload_file(file_path=self.full_local_path, object_name=os.path.join(self.path, self.filename, self.end_filename))

    @property
    def full_local_path(self):
        folder = os.path.join(current_app.root_path, self.path, self.filename)
        full_local_path = os.path.join(current_app.root_path, folder, self.end_filename)
        return full_local_path

    @property
    def full_bucket_path(self):
        return os.path.join(self.path, self.filename, self.end_filename)

    @property
    def end_filename(self):
        if self.is_local:
            folder = os.path.join(current_app.root_path, self.path, self.filename)
            end_filename = os.listdir(folder)[0]
        else:
            folder = os.path.join(self.path, self.filename)
            end_filename = funcs.list_files(folder_path=folder)[-1]
        return end_filename

    @property
    def src(self):
        if self.is_local:
            url = url_for("static", filename=funcs.join_parts(*Path(self.path).parts[1:], self.filename, self.end_filename))
            return url
        else:
            self.make_local()
            return self.src

    def empty(self):
        if not self.is_empty:
            funcs.silent_local_remove(self.full_local_path)
            funcs.delete_file(self.full_bucket_path)

    def remove(self):
        self.empty()
        db.session.delete(self)

    @property
    def is_local(self):
        local_folder = os.path.join(current_app.root_path, self.path, self.filename)
        return os.path.exists(local_folder) and os.listdir(local_folder)

    @property
    def is_global(self):
        folder = os.path.join(self.path, self.filename)
        exists = bool(funcs.list_files(folder_path=folder))
        return exists

    @property
    def is_empty(self):
        return not (self.is_local or self.is_local)

    def make_local(self):
        folder = os.path.join(current_app.root_path, self.path, self.filename)
        Path(folder).mkdir(parents=True, exist_ok=True)
        funcs.download_file(self.full_bucket_path, self.full_local_path)

    def __repr__(self):
        return "<File {}>".format(self.filename)

class Photo(db.Model, File):

    is_empty = db.Column(db.Boolean, default=True)
    replacement = db.Column(db.String(2048))

    def save(self, file, d=(256, 256), path=None):
        image = Image.open(file)
        new_image = image.resize((256, 256), Image.ANTIALIAS)
        new_image.format = image.format
        full_local_path = self.save_locally(file_format=image.format)
        print(full_local_path)
        new_image.save(full_local_path)
        self.upload_to_bucket()
        self.is_empty = False

    def empty(self):
        super(Photo, self).empty()
        self.is_empty = True

    def show(self):
        # For display in shell
        image = Image.open(self.full_path)
        image.show()

    @property
    def src(self):
        if not self.is_empty:
            return super(Photo, self).src
        return self.replacement

    def __repr__(self):
        return "<Picture {}>".format(self.filename)


def gravatar(text_to_digest, size=256):
    digest = md5(text_to_digest.encode("utf-8")).hexdigest()
    return "https://www.gravatar.com/avatar/{}?d=identicon&s={}".format(
        digest, size)


class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String)
    timestamp = db.Column(db.Float, index=True, default=time)

    object_role_id = db.Column(db.Integer, db.ForeignKey('role.id'))
    object_group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    object_project_id = db.Column(db.Integer, db.ForeignKey('project.id'))

    object_role = db.relationship("Role", foreign_keys=[object_role_id])
    object_group = db.relationship("Group", foreign_keys=[object_group_id])
    object_project = db.relationship("Project", foreign_keys=[object_project_id])

    sender_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    receiver_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))

    @hybrid_property
    def object(self):
        return self.object_group or self.object_project or self.object_role

    @hybrid_property
    def object_id(self):
        return self.object_group_id or self.object_project_id or self.object_role_id

    @property
    def raw(self):
        return {"type": self.type,
                "color": self.color,
                "icon": self.icon,
                "sender-name": self.sender.name,
                "sender-username": self.sender.username,
                "message": self.message,
                "sender-photo": self.sender.profile_photo.src,
                "object-name": getattr(self.object, 'handle', lambda: None)() or getattr(self.object, 'title', lambda: None)(),
                "object-photo": getattr(self.object, 'profile_pic', lambda: None)()}

    @property
    def color(self):
        return {"connect": "#3298dc",
                "ban": "hsl(348, 100%, 61%)",
                "invite": "#3298dc",
                "role": "#3273dc",
                "message": "#3298dc",
                "accepted-invite": "hsl(141, 53%, 53%)",
                "accepted-connect": "hsl(141, 53%, 53%)",
                "rejected-invite": "hsl(348, 100%, 61%)",
                "rejected-connect": "hsl(348, 100%, 61%)"}.get(self.type)

    @property
    def icon(self):
        return {"connect": "fa fa-user-friends",
                "ban": "fa fa-ban",
                "invite": "fa fa-envelope",
                "role": "fa fa-black-tie",
                "message": "fa fa-comments",
                "accepted-invite": "fa fa-envelope",
                "accepted-connect": "fa fa-user-friends",
                "rejected-invite": "fa fa-envelope",
                "rejected-connect": "fa fa-user-friends"}.get(self.type)

    @property
    def message(self):
        return {"connect": "wants to connect",
                "ban": "banned you from",
                "invite": "invited you to join",
                "role": "changed your role to",
                "message": "messaged you",
                "accepted-invite": "accepted your invite to",
                "accepted-connect": "accepted your attempt to connect",
                "rejected-invite": "rejected your invite to",
                "rejected-connect": "rejected your attempt to connect"}.get(self.type)

    @property
    def has_object(self):
        return {"connect": False,
                "ban": True,
                "invite": True,
                "role": True,
                "message": False,
                "accepted-invite": True,
                "accepted-connect": False,
                "rejected-invite": True,
                "rejected-connect": False}.get(self.type)

    def __repr__(self):
        return "<Notification {}>".format(self.type)


class Role(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, index=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    project_id = db.Column(db.Integer, db.ForeignKey('project.id', ondelete='CASCADE'))
    group = db.relationship("Group", back_populates="roles", foreign_keys=[group_id])
    project = db.relationship("Project", back_populates="roles", foreign_keys=[project_id])
    holders = db.relationship('Membership', back_populates="role")

    @hybrid_property
    def organisation_id(self):
        return self.group_id or self.project_id

    @hybrid_property
    def organisation(self):
        return self.group or self.project

    def __repr__(self):
        return "<Role {}>".format(self.title)


class Group(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    profile_pic_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    profile_pic = db.relationship("Photo", foreign_keys=[profile_pic_id])

    supergroup_id = db.Column(db.Integer, db.ForeignKey('group.id'))

    roles = db.relationship("Role")

    memberships = db.relationship(
        'Membership', backref='organisation', lazy='dynamic',
        foreign_keys='Membership.group_id')

    subgroups = db.relationship('Group', backref=db.backref("supergroup", remote_side=[id]))

    def __init__(self, **kwargs):
        super(Group, self).__init__(**kwargs)
        # do custom initialization here
        self.profile_pic = Picture(path=f"/static/profiles/groups/{self.handle}/profile_pic", replacement="/static/images/defaults/group.png")

    def __repr__(self):
        return "<Group {}>".format(self.handle)


class Project(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    handle = db.Column(db.String, index=True, unique=True)
    name = db.Column(db.String)
    description = db.Column(db.String)
    public = db.Column(db.Boolean, default=False)

    profile_pic_id = db.Column(db.Integer, db.ForeignKey('photo.id'))
    profile_pic = db.relationship("Photo", foreign_keys=[profile_pic_id])

    roles = db.relationship("Role")

    superproject_id = db.Column(db.Integer, db.ForeignKey('project.id'))

    memberships = db.relationship(
        'Membership')

    subprojects = db.relationship('Project', backref=db.backref("superproject", remote_side=[id]))

    def __init__(self, **kwargs):
        super(Project, self).__init__(**kwargs)
        # do custom initialization here
        self.profile_pic = Picture(path=f"/static/profiles/projects/{self.handle}/profile_pic", replacement="/static/images/defaults/project.png")

    def __repr__(self):
        return "<Project {}>".format(self.handle)


class Membership(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))
    group_id = db.Column(db.Integer, db.ForeignKey('group.id', ondelete='CASCADE'))
    project_id = db.Column(db.Integer, db.ForeignKey('project.id', ondelete='CASCADE'))
    group = db.relationship("Group", foreign_keys=[group_id])
    project = db.relationship("Project", foreign_keys=[project_id])
    role_id = db.Column(db.Integer, db.ForeignKey('role.id'))
    role = db.relationship("Role", foreign_keys=[role_id])

    @hybrid_property
    def organisation_id(self):
        return self.group_id or self.project_id

    @hybrid_property
    def organisation(self):
        return self.group or self.project

    def __repr__(self):
        return "<Membership {}>".format(self.role)
