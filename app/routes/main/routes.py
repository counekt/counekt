# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from app import db, models
import app.routes.main.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.main import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required

# ======== Routing =========================================================== #

# -------- Home page ---------------------------------------------------------- #


@bp.route("/")
@bp.route("/explore/")
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

        location = funcs.geocode(address)

        if not location:
            return json.dumps({'status': 'Non-valid location', 'box_id': 'location-field'})

        try:

            radius = float(radius)

        except ValueError:
            return json.dumps({'status': 'Non-valid radius', 'box_id': 'options-button'})

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

        query = models.User.get_explore_query(latitude=location.latitude, longitude=location.longitude, radius=radius, skill=skill, gender=gender, min_age=min_age, max_age=max_age)

        profiles = query.all()
        print(profiles)
        loc = {"lat": location.latitude, "lng": location.longitude, "zoom": funcs.get_zoom_from_rad(radius)}
        info = [{"username": p.username, "profile_photo": p.profile_photo.src, "name": p.name if p.name else p.username, "lat": p.latitude, "lng": p.longitude} for p in profiles]
        return json.dumps({'status': 'Successfully explored', 'url': url, 'info': info, 'loc': loc})

    return render_template("main.html", available_skills=current_app.config["AVAILABLE_SKILLS"], available_genders=current_app.config["AVAILABLE_GENDERS"], background=False, footer=False, exonavbar=True, ** q_strings)


@ bp.route("/about/", methods=['GET'])
def about():
    return render_template("about.html", background=True, size="medium", footer=True, navbar=True)


@ bp.route("/fiskefrikadeller/", methods=['GET'])
def fiskefrikadeller():
    return render_template("fiskefrikadeller.html", testvar="yes", background=True, size="medium", footer=True, navbar=True)


@ bp.route("/help/", methods=['GET'])
def help():
    return render_template("help.html", background=True, size="medium", footer=True, navbar=True)


@ bp.route("/settings/", methods=['GET'])
def settings():
    return render_template("settings.html", background=True, size="medium", footer=True, navbar=True)
