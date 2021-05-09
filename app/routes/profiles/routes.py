# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models
import app.routes.profiles.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.profiles import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required

from app.routes.profiles.user.routes import *
from app.routes.profiles.club.routes import *
from app.routes.profiles.project.routes import *


@ bp.route("/get/coordinates/", methods=["POST"])
def get_coordinates():
    if flask_request.method == 'POST':
        address = flask_request.form.get("address")
        location = funcs.geocode(address)
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'lat': location.latitude, 'lng': location.longitude})


@ bp.route("/get/address/", methods=["POST"])
def get_address():
    if flask_request.method == 'POST':
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")
        print(lat, lng)
        location = funcs.reverse_geocode([lat, lng])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address': location.address})


@ bp.route("/connect/<username>/", methods=["POST"])
def connect(username):
    user = models.User.query.filter_by(username=username).first()
    if user and flask_request.method == 'POST':
        sent_request = models.UserToUserRequest.query.filter_by(type="ally", sender=current_user, receiver=user).first()
        received_request = models.UserToUserRequest.query.filter_by(type="ally", receiver=current_user, sender=user).first()
        print(flask_request.form)
        if flask_request.form.get("do") and not sent_request and not received_request:
            request = models.UserToUserRequest(type="ally", sender=current_user, receiver=user)
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
            current_user.allies.remove(user)
            user.allies.remove(current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
    return json.dumps({'status': 'error'})


@ bp.route("/notifications/", methods=['GET', 'POST'])
def notifications():
    # POST request for marking notif as read
    if flask_request.method == 'POST':
        notif_id = flask_request.form.get("id")
        notification = models.Notification.query.filter_by(id=notif_id).first()
        if notification:
            notification.seen = True
            db.session.commit()
            return json.dumps({'status': 'success'})
        return json.dumps({'status': 'error'})

    notifications = current_user.notifications
    return render_template("notifications.html", background=True, size="medium", navbar=True, notifications=notifications)
