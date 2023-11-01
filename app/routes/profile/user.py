# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models
import app.routes.profile.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.profile import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
from sqlalchemy import exc

@ bp.route("/@<username>/", methods=["GET"])
@ bp.route("/user/<username>/", methods=["GET"])
def user(username):
    print(username)
    user = models.User.query.filter_by(username=username).first_or_404()
    print(user)
    return render_template("profile/user/profile.html", user=user, navbar=True, background=True, size="medium", models=models)


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
        print(file)

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
            current_user.photo.save(file=file)
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
        return json.dumps({'status': 'success', 'username': current_user.username, 'address':current_user.address, 'skill-bar':render_template("profile/skill-bar.html", skillrows=current_user.skillrows)})
    return render_template("profile/user/profile.html", user=current_user, background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/create/medium/", methods=["GET", "POST"])
@login_required
def create_medium():
    if flask_request.method == 'POST':
        action = flask_request.form.get("action")
        title = flask_request.form.get("title")
        text = flask_request.form.get("text")
        m_type = flask_request.form.get("type", "plain")
        target_id = flask_request.form.get("target_id", type=int)

        print(m_type)
        print(title)
        print(text)

        if (action == "submit" and not title) or (not title and not text):
            return json.dumps({'status': 'error'})
        try:
            if m_type == "plain":
                medium = models.Medium(title=title,content=text, author=current_user, public=True if action == "submit" else False)
                current_user.wall.append(medium)
                db.session.commit()
                return json.dumps({'status': 'success', 'id':medium.id, "html":render_template("comms/wall/medium.html", medium=medium)})
            
            if m_type == "quote":
                quote = models.Medium.query.get(target_id)
                medium = models.Medium(title=title,content=text, author=current_user, public=True if action == "submit" else False, with_quote=True)
                quote.quote_replies.append(medium)
                current_user.wall.append(medium)
                db.session.commit()
                return json.dumps({'status': 'success', 'id':medium.id, "html":render_template("comms/wall/medium.html", medium=medium)})

            if m_type == "reply":
                original = models.Medium.query.get(target_id)
                reply = models.Medium(title=title,content=text, author=current_user, public=True if action == "submit" else False)
                original.replies.append(reply)
                db.session.commit()
                return json.dumps({'status': 'success', 'id':reply.id, 'author':{'username':reply.author.username}})
        except exc.SQLAlchemyError:
            return json.dumps({'status': 'Medium not submitted'})

    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profile/user/profile.html", user=current_user, noscroll=True, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", models=models)

@bp.route("/delete/medium/", methods=["POST"])
@login_required
def delete_medium():
    if flask_request.method == 'POST':
        target_id = flask_request.form.get("target_id", type=int)
        medium = current_user.wall.media.filter_by(id=target_id).first()
        db.session.delete(medium)
        db.session.commit()
        return json.dumps({'status': 'success'})

@ bp.route("/user/<username>/medium/<id>/", methods=["GET", "POST"])
@ bp.route("/@<username>/medium/<id>/", methods=["GET", "POST"])
def user_medium(username, id):
    user = models.User.query.filter_by(username=username).first()
    medium = user.wall.media.filter_by(id=id).first()
    if flask_request.method == 'POST':
        return json.dumps({'status': 'success', "medium":{"author":{"dname":medium.author.dname, "username":medium.author.username, "symbol":"@", "photo_src":medium.author.photo.src,"href":medium.author.href}, "id":medium.id, "creation_datetime":medium.creation_datetime.strftime("%m/%d/%Y, %H:%M:%S"), "title":str(medium.title), "content":str(medium.content),"reply_count":medium.reply_count,"quote_count":medium.quote_count, "is_hearted":medium.is_hearted(current_user) if current_user.is_authenticated else False}})
    return render_template("comms/medium/by-user-wrapped.html", medium=medium, navbar=True, background=True, size="medium", models=models, url=flask_request.url, max=max,min=min)

@ bp.route("/user/<username>/photo/", methods=["GET", "POST"])
def user_photo(username):
    user = models.User.query.filter_by(username=username).first()
    if not user:
        abort(404)
    skillrows = [user.skills.all()[i:i + 3] for i in range(0, len(user.skills.all()), 3)]
    return render_template("profile/user/profile.html", user=user, noscroll=True, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", models=models)
