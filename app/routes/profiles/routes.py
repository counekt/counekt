# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models
import app.routes.profiles.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.profiles import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required


@ bp.route("/user/<username>/", methods=["GET", "POST"])
def user(username):
    user = models.User.query.filter_by(username=username).first()
    if not user:
        abort(404)
    skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", models=models)


@ bp.route("/settings/profile/", methods=["GET", "POST"])
@login_required
def edit_user():
    if flask_request.method == 'POST':
        name = flask_request.form.get("name")
        bio = flask_request.form.get("bio")

        show_location = int(flask_request.form.get("show-location"))
        is_visible = flask_request.form.get("visible")
        if is_visible:
            is_visible = int(is_visible)
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")

        month = flask_request.form.get("month")
        day = flask_request.form.get("day")
        year = flask_request.form.get("year")

        gender = flask_request.form.get("gender")
        skills = eval(flask_request.form.get("skills"))

        file = flask_request.files.get("photo")

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
            return json.dumps({'status': 'Your bio can\'t exceed a length of 160 characters', 'box_id': 'bio'})
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
    if not user:
        abort(404)
    skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", photo_src=user.profile_photo.src, noscroll=True, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", footer=True, models=models)


@ bp.route("/create/club/", methods=["GET", "POST"])
@login_required
def create_club():
    if flask_request.method == 'POST':
        handle = flask_request.form.get("handle")
        name = flask_request.form.get("name")
        description = flask_request.form.get("description")

        public = bool(flask_request.form.get("public"))

        show_location = int(flask_request.form.get("show-location"))
        is_visible = int(bool(flask_request.form.get("visible")))
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")

        #skills = eval(flask_request.form.get("skills"))

        file = flask_request.files.get("photo")

        if not handle:
            return json.dumps({'status': 'Handle must be filled in', 'box_id': 'handle'})

        if not name:
            return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

        if not description:
            return json.dumps({'status': 'Description must be filled in', 'box_id': 'description'})

        if not models.Club.query.filter_by(handle=handle).first() is None:
            return json.dumps({'status': 'Handle already taken', 'box_id': 'handle'})

        if len(description.strip()) > 160:
            return json.dumps({'status': 'Your Club\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

        club = models.Club(handle=handle.strip(), name=name.strip(), description=description.strip(), public=public, members=[current_user])

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Club\'s location and or be visible on the map', 'box_id': 'location'})

            location = funcs.reverse_geocode([lat, lng])
            if not location:
                return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
            club.set_location(location=location)

            club.show_location = True
            if is_visible:
                club.is_visible = True
        else:
            club.latitude = None
            club.longitude = None
            club.sin_rad_lat = None
            club.cos_rad_lat = None
            club.rad_lng = None
            club.address = None
            club.is_visible = False
            club.show_location = False

        if file:
            club.profile_photo.save(file=file)

        """
        # Add skills that are not already there
        for skill in skills:
            if not current_user.skills.filter_by(title=skill).first():
                skill = models.Skill(owner=current_user, title=skill)
                db.session.add(skill)

        # Delete skills that are meant to be deleted
        for skill in current_user.skills:
            if not skill.title in skills:
                db.session.delete(skill)
        """
        current_user.clubs.append(club)
        db.session.commit()
        return json.dumps({'status': 'success'})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/create/project/", methods=["GET", "POST"])
@login_required
def create_project():
    if flask_request.method == 'POST':
        handle = flask_request.form.get("handle")
        name = flask_request.form.get("name")
        description = flask_request.form.get("description")

        public = bool(flask_request.form.get("public"))

        show_location = int(flask_request.form.get("show-location"))
        is_visible = int(bool(flask_request.form.get("visible")))
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")

        skills = eval(flask_request.form.get("skills"))

        file = flask_request.files.get("photo")

        if not handle:
            return json.dumps({'status': 'Handle must be filled in', 'box_id': 'handle'})

        if not name:
            return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

        if not description:
            return json.dumps({'status': 'Description must be filled in', 'box_id': 'description'})

        if not models.Club.query.filter_by(handle=handle).first() is None:
            return json.dumps({'status': 'Handle already taken', 'box_id': 'handle'})

        if len(description.strip()) > 160:
            return json.dumps({'status': 'Your Project\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

        project = models.Project(handle=handle.strip(), name=name.strip(), description=description.strip(), public=public, members=[current_user])

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Project\'s location and or be visible on the map', 'box_id': 'location'})

            location = funcs.reverse_geocode([lat, lng])
            if not location:
                return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
            project.set_location(location=location)

            project.show_location = True
            if is_visible:
                project.is_visible = True
        else:
            project.latitude = None
            project.longitude = None
            project.sin_rad_lat = None
            project.cos_rad_lat = None
            project.rad_lng = None
            project.address = None
            project.is_visible = False
            project.show_location = False

        if file:
            project.profile_photo.save(file=file)

        # Add skills that are not already there
        """
        for skill in skills:
            if not current_user.skills.filter_by(title=skill).first():
                skill = models.Skill(owner=current_user, title=skill)
                db.session.add(skill)
        
        # Delete skills that are meant to be deleted
        for skill in current_user.skills:
            if not skill.title in skills:
                db.session.delete(skill)
        """
        current_user.projects.append(project)
        db.session.commit()
        return json.dumps({'status': 'success'})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/get/coordinates/", methods=["POST"])
def get_coordinates():
    if flask_request.method == 'POST':
        address = flask_request.form.get("address")
        location = funcs.geocode(address)
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'lat': location.latitude, 'lng': location.longitude})


@ bp.route("/get/address/", methods=["POST"])
def get_address():
    if flask_request.method == 'POST':
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")
        print(lat, lng)
        location = funcs.reverse_geocode([lat, lng])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address': location.address})


@ bp.route("/connect/<username>/", methods=["POST"])
def connect(username):
    user = models.User.query.filter_by(username=username).first()
    if user and flask_request.method == 'POST':
        sent_request = models.UserToUserRequest.query.filter_by(type="ally", sender=current_user, receiver=user).first()
        received_request = models.UserToUserRequest.query.filter_by(type="ally", receiver=current_user, sender=user).first()
        print(flask_request.form)
        if flask_request.form.get("do") and not sent_request and not received_request:
            request = models.UserToUserRequest(type="ally", sender=current_user, receiver=user)
            db.session.add(request)
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("accept") and received_request:
            received_request.accept()
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("undo") and sent_request:
            sent_request.regret()
            db.session.commit()
            return json.dumps({'status': 'success'})
        elif flask_request.form.get("disconnect"):
            current_user.allies.remove(user)
            user.allies.remove(current_user)
            db.session.commit()
            return json.dumps({'status': 'success'})
    return json.dumps({'status': 'error'})


@ bp.route("/notifications/", methods=['GET', 'POST'])
def notifications():
    # POST request for marking notif as read
    if flask_request.method == 'POST':
        notif_id = flask_request.form.get("id")
        notification = models.Notification.query.filter_by(id=notif_id).first()
        if notification:
            notification.seen = True
            db.session.commit()
            return json.dumps({'status': 'success'})
        return json.dumps({'status': 'error'})

    notifications = current_user.notifications
    return render_template("notifications.html", background=True, size="medium", navbar=True, notifications=notifications)
