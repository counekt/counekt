from app.routes.stats import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
from flask import redirect, url_for, render_template, abort, request, current_app
from app import db, models
import app.routes.stats.funcs as funcs

@bp.route("/")
@bp.route("/stats/")
def stats():
	return render_template("stats/stats.html", size="medium", footer=True, navbar=True, models=models)