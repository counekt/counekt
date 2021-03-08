# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from app import db, models
import app.profiles.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.profiles import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required


@ bp.route("/user/<username>/", methods=["GET", "POST"])
def user(username):
    user = models.User.query.filter_by(username=username).first()
    if not user:
        abort(404)
    skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium")


@ bp.route("/settings/profile/", methods=["GET", "POST"])
@login_required
def edit_user():
    if request.method == 'POST':
        name = request.form.get("name")
        bio = request.form.get("bio")

        show_location = int(request.form.get("show-location"))
        is_visible = request.form.get("visible")
        if is_visible:
            is_visible = int(is_visible)
        lat = request.form.get("lat")
        lng = request.form.get("lng")

        month = request.form.get("month")
        day = request.form.get("day")
        year = request.form.get("year")

        gender = request.form.get("gender")
        skills = eval(request.form.get("skills"))

        file = request.files.get("photo")

        if not name:
            return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your location and or be visible on the map', 'box_id': 'location'})

            if [current_user.latitude, current_user.longitude] != [float(lat), float(lng)]:
                location = funcs.reverse_geocode([lat, lng])
                if not location:
                    return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
                current_user.set_location(location=location)

            current_user.show_location = True
            if is_visible:
                current_user.is_visible = True
        else:
            current_user.latitude = None
            current_user.longitude = None
            current_user.sin_rad_lat = None
            current_user.cos_rad_lat = None
            current_user.rad_lng = None
            current_user.address = None
            current_user.is_visible = False
            current_user.show_location = False

        if not month or not day or not year:
            return json.dumps({'status': 'Birthday must be filled in', 'box_id': 'birthdate'})

        try:
            birthdate = date(month=int(month), day=int(day), year=int(year))
        except ValueError:
            return json.dumps({'status': 'Invalid date', 'box_id': 'birthdate'})

        if not funcs.get_age(birthdate) >= 13:
            return json.dumps({'status': 'You must be over the age of 13', 'box_id': 'birthdate'})

        if len(bio) > 160:
            return json.dumps({'status': 'Your bio can\'t exceed a lenght of 160 characters', 'box_id': 'bio'})
        current_user.bio = bio.strip()

        if file:
            current_user.profile_photo.save(file=file)
        current_user.name = name.strip()
        current_user.set_birthdate(birthdate)
        current_user.gender = gender

        # Add skills that are not already there
        for skill in skills:
            if not current_user.skills.filter_by(title=skill).first():
                skill = models.Skill(owner=current_user, title=skill)
                db.session.add(skill)

        # Delete skills that are meant to be deleted
        for skill in current_user.skills:
            if not skill.title in skills:
                db.session.delete(skill)

        db.session.commit()
        return json.dumps({'status': 'success', 'username': current_user.username})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/user/<username>/photo/", methods=["GET", "POST"])
def user_photo(username):
    user = models.User.query.filter_by(username=username).first()
    skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=user, noscroll=True, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", footer=True)


@ bp.route("/get/coordinates/", methods=["POST"])
def get_coordinates():
    if request.method == 'POST':
        address = request.form.get("address")
        location = funcs.geocode(address)
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'lat': location.latitude, 'lng': location.longitude})


@ bp.route("/get/address/", methods=["POST"])
def get_address():
    if request.method == 'POST':
        lat = request.form.get("lat")
        lng = request.form.get("lng")
        print(lat, lng)
        location = funcs.reverse_geocode([lat, lng])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address': location.address})
