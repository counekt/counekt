from app.routes.index import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
from flask import redirect, url_for, render_template, abort, request, current_app
from app import db, models
import app.routes.index.funcs as funcs


@bp.route("/")
@bp.route("/index/")
def index():
	return render_template("index/index.html", size="medium", footer=True, navbar=True)
