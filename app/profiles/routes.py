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
    return render_template("profiles/user/profile.html", user=user, available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", footer=True)


@ bp.route("/settings/profile/", methods=["GET", "POST"])
@login_required
def edit_user():
    user = current_user
    if request.method == 'POST':
        name = request.form.get("name")
        bio = request.form.get("bio")

        explore_visible = request.form.get("explore_visible")
        address = request.form.get("address")
        lat = request.form.get("lat")
        lng = request.form.get("lng")

        month = request.form.get("month")
        day = request.form.get("day")
        year = request.form.get("year")

        gender = request.form.get("gender")
        skills = eval(request.form.get("skills"))

        file = request.files.get("image")

        if not name:
            return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

        save_location = False
        if explore_visible:
            if not address:
                return json.dumps({'status': 'Location must be filled in', 'box_id': 'location'})

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in', 'box_id': 'location'})

            location = geocode(address)
            if not (location.latitude, location.longitude) == (float(lat), float(lng)):
                return json.dumps({'status': 'Coordinates do not match address', 'box_id': 'location'})
        elif address and lat and lng:
            location = geocode(address)
            if not (location.latitude, location.longitude) == (float(lat), float(lng)):
                return json.dumps({'status': 'Coordinates do not match address', 'box_id': 'location'})
            save_location = True

        if not month or not day or not year:
            return json.dumps({'status': 'Birthday must be filled in', 'box_id': 'birthdate'})

        try:
            birthdate = date(month=int(month), day=int(day), year=int(year))
        except ValueError:
            return json.dumps({'status': 'Invalid date', 'box_id': 'birthdate'})

        if not get_age(birthdate) >= 13:
            return json.dumps({'status': 'You must be over the age of 13', 'box_id': 'birthdate'})

        if file:
            image = Image.open(file)
            new_image = image.resize((256, 256), Image.ANTIALIAS)
            new_image.format = image.format
            current_user.profile_photo.save(image=new_image)
        current_user.name = name.strip()
        current_user.bio = bio.strip()
        if (save_location or explore_visible) and ((current_user.latitude, current_user.longitude) != (float(lat), float(lng)) or current_user.address != address):
            current_user.set_location(location=location, prelocated=True)
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
        return json.dumps({'status': 'success'})
    return render_template("profiles/user/profile.html", user=user, edit=True, available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", footer=True)


@ bp.route("/user/<username>/photo/", methods=["GET", "POST"])
def user_photo(username):
    user = models.User.query.filter_by(username=username).first()
    return render_template("profiles/user/profile.html", user=user, photo=True, available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", footer=True)


@bp.route("/get/coordinates/", methods=["POST"])
def get_coordinates():
    if request.method == 'POST':
        address = request.form.get("address")
        location = funcs.geocode(address)
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'lat': location.latitude, 'lng': location.longitude})


@bp.route("/get/address/", methods=["POST"])
def get_address():
    if request.method == 'POST':
        lat = request.form.get("lat")
        lng = request.form.get("lng")
        print(lat, lng)
        location = funcs.reverse_geocode([lat, lng])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address': location.address})
