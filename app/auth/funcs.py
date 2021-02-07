from app.funcs import *
import json
import re
from app import db, models
from app.email import send_email
from flask import render_template


def verify_traits(month, day, year, gender):
    if not month or not day or not year:
        return json.dumps({'status': 'Birthdate must be filled in', 'box_ids': ['birthdate']})

    birthdate = date(month=int(month), day=int(day), year=int(year))
    if not get_age(birthdate) >= 13:
        return json.dumps({'status': 'You must be over the age of 13', 'box_ids': ['birthdate']})

    if not gender in ["Unspecified", "Male", "Female", "Other"]:
        return json.dumps({'status': 'Invalid gender', 'box_ids': ['gender']})


def verify_identifiers(username, email):
    if not username:
        return json.dumps({'status': 'Username must be filled in', 'box_ids': ['username']})

    if not email:
        return json.dumps({'status': 'Email must be filled in', 'box_ids': ['email']})

    if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
        return json.dumps({'status': 'Invalid email address', 'box_ids': ['email']})

    if not models.User.query.filter_by(username=username).first() is None:
        print("taken")
        # If only expired users with same username: delete them all and pass
        expired_user = models.User.query.filter_by(email=email).filter(models.User.token_is_expired, models.User.is_activated == False).first()
        print(expired_user)
        if not models.User.query.filter_by(username=username).filter(models.User.token_is_expired, models.User.is_activated == False).first() is None:
            print("inactive")
            models.User.query.filter_by(username=username).filter(models.User.token_is_expired, models.User.is_activated == False).delete(synchronize_session='fetch')
            db.session.commit()
        else:
            return json.dumps({'status': 'Username taken', 'box_ids': ['username']})

    if not models.User.query.filter_by(email=email).first() is None:
        print("taken")
        # If only expired users with same email: delete them all and pass
        expired_user = models.User.query.filter_by(email=email).filter(models.User.token_is_expired, models.User.is_activated == False).first()
        print(expired_user)
        if not models.User.query.filter_by(email=email).filter(models.User.token_is_expired, models.User.is_activated == False).first() is None:
            models.User.query.filter_by(email=email).filter(models.User.token_is_expired, models.User.is_activated == False).delete(synchronize_session='fetch')
            db.session.commit()
        else:
            return json.dumps({'status': 'Email taken', 'box_ids': ['email']})


def verify_secret(password, repeat_password):
    if not password:
        return json.dumps({'status': 'Password must be filled in', 'box_ids': ['password']})

    if not repeat_password:
        return json.dumps({'status': 'Repeat Password must be filled in', 'box_ids': ['repeat-password']})

    if not password == repeat_password:
        return json.dumps({'status': 'Passwords don\'t match', 'box_ids': ['password', 'repeat-password']})


def send_auth_email(user, sender):
    if user.token:
        token = user.refresh_token()
    else:
        token = user.get_token()
    sent = send_email('[CTW] Activate your account',
                      sender=sender,
                      recipients=[user.email],
                      text_body=render_template('email/auth.txt',
                                                user=user, token=token),
                      html_body=render_template('email/auth.html',
                                                user=user, token=token))
    return sent
