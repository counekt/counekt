# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models, w3
import app.routes.idea.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.profile import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required


@ bp.route("/create/idea/", methods=["GET", "POST"])
@login_required
def create_idea():
    if flask_request.method == 'POST':

        step = flask_request.form.get("step")

        if step == "step-1":

            handle = flask_request.form.get("handle")
            name = flask_request.form.get("name")
            description = flask_request.form.get("description")


            show_location = int(flask_request.form.get("show-location"))
            lat = flask_request.form.get("lat")
            lng = flask_request.form.get("lng")

            result = funcs.verify_credentials(handle=handle,name=name,description=description,show_location=show_location,lat=lat,lng=lng)
            if result:
                return result
            return json.dumps({'status': 'success'})

        elif step == "step-2":

            handle = flask_request.form.get("handle")
            name = flask_request.form.get("name")
            description = flask_request.form.get("description")


            show_location = int(flask_request.form.get("show-location"))
            lat = flask_request.form.get("lat")
            lng = flask_request.form.get("lng")

            public = bool(flask_request.form.get("public"))
            is_visible = int(bool(flask_request.form.get("visible")))

            result = funcs.verify_credentials(handle=handle,name=name,description=description,show_location=show_location,lat=lat,lng=lng)
            if result:
                return result

            file = flask_request.files.get("photo")

            ideaAddress = flask_request.form.get("ideaAddress");

            idea = models.Idea(handle=handle.strip(), name=name.strip(), description=description.strip(), public=public, members=[current_user])

            if show_location:

                location = funcs.reverse_geocode([lat, lng])
                if not location:
                    return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
                idea.set_location(location=location)

                idea.show_location = True
                if is_visible:
                    idea.is_visible = True
            else:
                idea.latitude = None
                idea.longitude = None
                idea.sin_rad_lat = None
                idea.cos_rad_lat = None
                idea.rad_lng = None
                idea.address = None
                idea.is_visible = False
                idea.show_location = False

            if file:
                idea.profile_photo.save(file=file)

            if not ideaAddress or w3.eth.getCode(ideaAddress) != w3.eth.getCode("0xeaF64BC8bf09BD13829e4d9d7a2173824d71AbdC"):
                return json.dumps({'status': 'Deployment did not go through!', 'box_id': ''})

            idea.address = ideaAddress
            
        db.session.add(idea)
        db.session.commit()
        return json.dumps({'status': 'success', 'handle': handle})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profile/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/idea/<handle>/", methods=["GET", "POST"])
@ bp.route("/$<handle>/", methods=["GET", "POST"])
def idea(handle):
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    #if not idea or (not idea.public and not current_user in idea.group.members) and not current_user in idea.viewers:
        #abort(404)
    #skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profile/idea/profile.html", idea=idea, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], navbar=True, background=True, size="medium", models=models)


@ bp.route("/idea/<handle>/edit/", methods=["GET", "POST"])
@ bp.route("/$<handle>/edit/", methods=["GET", "POST"])
@login_required
def edit_idea(handle):
    if not handle:
        abort(404)
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    if not idea:
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
            return json.dumps({'status': 'Your Idea\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

        idea.name = name
        idea.description = description.strip()
        idea.public = public

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Idea\'s location and or be visible on the map', 'box_id': 'location'})

            location = funcs.reverse_geocode([lat, lng])
            if not location:
                return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
            idea.set_location(location=location)

            idea.show_location = True
            if is_visible:
                idea.is_visible = True
        else:
            idea.latitude = None
            idea.longitude = None
            idea.sin_rad_lat = None
            idea.cos_rad_lat = None
            idea.rad_lng = None
            idea.address = None
            idea.is_visible = False
            idea.show_location = False

        if file:
            idea.profile_photo.save(file=file)

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
    return render_template("profile/idea/profile.html", idea=idea, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/idea/<handle>/members/", methods=["GET"])
@ bp.route("/$<handle>/members/", methods=["GET"])
@login_required
def idea_add_members(handle):
    if not handle:
        abort(404)
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    if not idea:
        abort(404)

    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profile/idea/profile.html", idea=idea, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)
