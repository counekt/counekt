from flask import redirect, url_for, render_template, abort, request, current_app
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
from app import db, models
from app.routes.comms import bp

@login_required
@ bp.route("/messages/", methods=["GET", "POST"])
def messages():
    #messages = models.Message.query.filter_by(handle=handle).first()
    #skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("comms/messages.html", navbar=True, background=True, size="medium", models=models)
