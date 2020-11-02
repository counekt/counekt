# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from flask import Markup
from app import db
from app.models import get_explore_query
import app.main.funcs as funcs
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.main import bp

# ======== Routing =========================================================== #

# -------- Home page ---------------------------------------------------------- #


@bp.route("/")
@bp.route("/main/", methods=['GET', 'POST'])
def main():
    q_address = request.args.get('loc')
    q_radius = request.args.get('rad')
    q_skill = request.args.get('ski')
    q_gender = request.args.get('gen')
    q_min_age = request.args.get('min')
    q_max_age = request.args.get('max')

    q_strings = {"selected_address": q_address, "selected_radius": q_radius, "selected_skill": q_skill, "selected_gender": q_gender, "selected_min_age": q_min_age, "selected_max_age": q_max_age}

    if request.method == 'POST':

        address = request.form.get("location")
        skill = request.form.get("skill")
        radius = request.form.get("radius")
        gender = request.form.get("gender")
        min_age = request.form.get("min_age")
        max_age = request.form.get("max_age")

        print(address)
        print(radius)
        print(skill)
        print(gender)
        print(min_age)
        print(max_age)

        location = funcs.geocode(address)
        if not location:
            print("Non-valid location")
            return json.dumps({'status': 'Non-valid location', 'box_id': 'location-field'})

        try:
            radius = float(radius)
        except ValueError:
            print("Non-valid radius")
            return json.dumps({'status': 'Non-valid radius', 'box_id': 'options-button'})

        print(f"Successfully verified")

        url = f'/main?loc={address}&rad={radius}'

        if skill:
            if skill in current_app.config["AVAILABLE_SKILLS"]:
                url += f'&ski={skill}'
        if gender:
            if gender in current_app.config["AVAILABLE_GENDERS"]:
                url += f'&gen={gender}'
        if min_age:
            url += f'&min={min_age}'
        if max_age:
            url += f'&max={max_age}'

        query = get_explore_query(latitude=location.latitude, longitude=location.longitude, radius=radius, skill=skill, gender=gender, min_age=min_age, max_age=max_age)
        profiles = query.all()
        print(profiles)
        loc = {"lat": location.latitude, "lng": location.longitude, "zoom": funcs.get_zoom_from_rad(radius)}
        info = [{"username": p.username, "name": p.name, "lat": p.latitude, "lng": p.longitude} for p in profiles]
        return json.dumps({'status': 'Successfully explored', 'url': url, 'info': info, 'loc': loc})

    return render_template("main.html", available_skills=current_app.config["AVAILABLE_SKILLS"], available_genders=current_app.config["AVAILABLE_GENDERS"], background=False, footer=False, ** q_strings)


@bp.route("/login/", methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("main.main"))

    if request.method == 'POST':
        username = request.form.get("username")
        password = request.form.get("password")

        if not username:
            return json.dumps({'status': 'Username must be filled in', 'box_ids': ['username']})

        if not password:
            return json.dumps({'status': 'Password must be filled in', 'box_ids': ['password']})

        user = models.User.query.filter_by(username=username).first()

        if user is None or not user.check_password(password):
            return json.dumps({'status': 'Incorrect username or password', 'box_ids': ['username', 'password']})

        login_user(user, remember=True)
        return json.dumps({'status': 'success'})
    return render_template("login.html", background=True, size="medium", footer=True)


@bp.route("/about/", methods=['GET'])
def about():
    return render_template("about.html", background=True, size="medium", footer=True)


@bp.route("/fiskefrikadeller/", methods=['GET'])
def fiskefrikadeller():
    return render_template("fiskefrikadeller.html", testvar="yes", background=True, size="medium", footer=True)


@bp.route("/help/", methods=['GET'])
def help():
    return render_template("help.html", background=True, size="medium", footer=True)


@bp.route("/settings/", methods=['GET'])
def settings():
    return render_template("settings.html", background=True, size="medium", footer=True)


@bp.route("/register/", methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for("main.main"))

    if request.method == 'POST':
        username = request.form.get("username")
        password = request.form.get("password")
        repeat_password = request.form.get("repeat-password")

        if not username:
            return json.dumps({'status': 'Username must be filled in', 'box_ids': ['username']})

        if not password:
            return json.dumps({'status': 'Password must be filled in', 'box_ids': ['password']})

        if not repeat_password:
            return json.dumps({'status': 'Repeat Password must be filled in', 'box_ids': ['repeat-password']})

        if not models.User.query.filter_by(username=username).first() is None:
            return json.dumps({'status': 'Username taken', 'box_ids': ['username']})

        if not password == repeat_password:
            return json.dumps({'status': 'Passwords don\'t match', 'box_ids': ['password', 'repeat-password']})

        user = models.User(username=username)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        login_user(user, remember=True)
        return json.dumps({'status': 'success'})

    return render_template("register.html", background=True, size="medium", footer=True)


@bp.route("/logout/", methods=['GET'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('main.login'))
