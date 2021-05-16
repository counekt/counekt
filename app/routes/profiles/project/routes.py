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

        project = models.Project(handle=handle.strip(), name=name.strip(), description=description.strip(), public=public, members=[current_user])

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Club\'s location and or be visible on the map', 'box_id': 'location'})

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
        db.session.commit()
        return json.dumps({'status': 'success', 'handle': handle})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/project/<handle>/", methods=["GET", "POST"])
@ bp.route("/£<handle>/", methods=["GET", "POST"])
def project(handle):
    project = models.Project.query.filter_by(handle=handle).first()
    if not project or (not project.public and not current_user in project.group.members):
        abort(404)
    #skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profiles/project/profile.html", project=project, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", models=models)


@ bp.route("/project/<handle>/edit/", methods=["GET", "POST"])
@ bp.route("/£<handle>/edit/", methods=["GET", "POST"])
@login_required
def edit_project(handle):
    if not handle:
        abort(404)
    project = models.Project.query.filter_by(handle=handle).first()
    if not project:
        abort(404)
    if flask_request.method == 'POST':
        name = flask_request.form.get("name")
        description = flask_request.form.get("description")

        public = bool(flask_request.form.get("public"))

        show_location = int(flask_request.form.get("show-location"))
        is_visible = int(bool(flask_request.form.get("visible")))
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")

        #skills = eval(flask_request.form.get("skills"))

        file = flask_request.files.get("photo")

        if not name:
            return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

        if not description:
            return json.dumps({'status': 'Description must be filled in', 'box_id': 'description'})

        if len(description.strip()) > 160:
            return json.dumps({'status': 'Your Club\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

        project.name = name
        project.description = description.strip()
        project.public = public

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Club\'s location and or be visible on the map', 'box_id': 'location'})

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
        db.session.commit()
        return json.dumps({'status': 'success', 'handle': handle})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/project/profile.html", project=project, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/project/<handle>/members/", methods=["GET", "POST"])
@ bp.route("/£<handle>/members/", methods=["GET", "POST"])
@login_required
def project_add_members(handle):
    if not handle:
        abort(404)
    project = models.Project.query.filter_by(handle=handle).first()
    if not project:
        abort(404)
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profiles/project/profile.html", project=project, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)
