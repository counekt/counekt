from flask import redirect, url_for, render_template, abort, request, current_app
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
from app import db, models
from app.routes.comms import bp

@login_required
@ bp.route("/messages/", methods=["GET", "POST"])
def messages():
    #convos = models.Convo.query.filter_by(handle=handle).first()
    #skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("comms/messages.html", navbar=True, background=True, size="medium", models=models)

@login_required
@ bp.route("/message/<username>/", methods=["GET", "POST"])
def message(username):
    user = models.User.query.filter_by(username=username).first()
    if not user:
        abort(404)
    convo = models.Convo.query.filter(models.Convo.member_count==2,models.Convo.members.contains(user), models.Convo.members.contains(current_user))

    print(convo)
    return render_template("comms/message.html", user=user, convo=convo, navbar=True, background=True, size="medium", models=models)
