from flask import redirect, url_for, render_template, abort, current_app, jsonify
from flask import request as flask_request
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
from app import db, models
from app.routes.comms import bp
import app.routes.comms.funcs as funcs
from urllib.parse import urlencode
from datetime import datetime

@login_required
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
    return render_template("comms/notifications/notifications.html", background=True, size="medium", navbar=True, notifications=notifications)
