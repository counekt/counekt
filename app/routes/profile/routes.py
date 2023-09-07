# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.profile import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required

from app.routes.profile.user import *
from app.routes.erc360.routes import *




@ bp.route("/get/associates/", methods=["POST"])
def get_associates():
    if flask_request.method == 'POST':
        text = flask_request.form.get("text")
        already_chosen = eval(flask_request.form.get("already_chosen"))
        associates = current_user.get_associates_from_text(text, already_chosen).limit(10).all()
        formatted_associates = \
        [{"username": associate.username,\
        "name": associate.name,\
        "bio": associate.bio,\
        "photo_src": associate.profile_photo.src,\
        "tick": associate.tick} for associate in associates]
        return json.dumps({'status': 'success', 'associates': formatted_associates})

@ bp.route("/connect/<username>/", methods=["POST"])
def connect(username):
    user = models.User.query.filter_by(username=username).first()
    if user and flask_request.method == 'POST':
        sent_request = models.UserToUserRequest.query.filter_by(type="associate", sender=current_user, receiver=user).first()
        received_request = models.UserToUserRequest.query.filter_by(type="associate", receiver=current_user, sender=user).first()
        if flask_request.form.get("do") and not sent_request and not received_request:
            request = models.UserToUserRequest(type="associate", sender=current_user, receiver=user)
            db.session.add(request)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("accept") and received_request:
            received_request.accept()
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("undo") and sent_request:
            sent_request.regret()
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("disconnect"):
            current_user.associates.remove(user)
            user.associates.remove(current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
        return json.dumps({'status': 'error'})