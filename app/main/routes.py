# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from flask import Markup
from app import db
from app.models import get_explore_query
from app.main.funcs import geocode, get_listing_info
import json
import folium
from folium.plugins import FastMarkerCluster
from folium.plugins import Fullscreen
from folium import FeatureGroup, LayerControl, Map, Marker
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

        location = geocode(address)
        if not location:
            print("Non-valid location")
            return json.dumps({'status': 'Non-valid location', 'box_id': 'location-field'})

        try:
            float(radius)
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
        profiles = query.limit(5).all()
        print(profiles)
        info = [p.username for p in profiles]
        return json.dumps({'status': 'Successfully explored', 'url': url, 'info': info})

    _map = folium.Map(location=[55.676111, 12.568333], tiles='CartoDBpositron', min_zoom=2, max_zoom=13, zoom_start=13, max_bounds=True, control_scale=True)

    return render_template("main.html", available_skills=current_app.config["AVAILABLE_SKILLS"], available_genders=current_app.config["AVAILABLE_GENDERS"], ** q_strings)


@bp.route("/login/", methods=['GET'])
def login():
    return render_template("login.html")
    

@bp.route("/about/", methods=['GET'])
def about():
    return render_template("about.html")


@bp.route("/help/", methods=['GET'])
def help():
    return render_template("help.html")


@bp.route("/settings/", methods=['GET'])
def settings():
    return render_template("settings.html")
