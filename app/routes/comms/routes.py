from flask import redirect, url_for, render_template, abort, request, current_app
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
from app import db, models
from app.routes.comms import bp
from sqlalchemy import func, inspect


@login_required
@ bp.route("/messages/", methods=["GET", "POST"])
def messages():
    convos = current_user.convos
    return render_template("comms/messages.html", navbar=True, background=True, size="medium", models=models, convos = convos)

@login_required
@ bp.route("/message/<username>/", methods=["GET", "POST"])
def message(username):
    user = models.User.query.filter_by(username=username).first()
    if not user:
        abort(404)
    # Get the dialogue between current_user and user if it exists
    convo = models.Convo.query.join(models.Convo.members).group_by(models.Convo.id).having(func.count()==2).filter(models.Convo.members.contains(user), models.Convo.members.contains(current_user))
    return render_template("comms/message.html", user=user, convo=convo, navbar=True, background=True, size="medium", models=models)

@login_required
@ bp.route("/convo/<id>/", methods=["GET", "POST"])
def conversation(id):
    convo = models.Convo.query.get(id)
    return render_template("comms/message.html", convo=convo, navbar=True, background=True, size="medium", models=models)
