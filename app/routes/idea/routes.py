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
from app.routes.idea import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import app.models as models

@bp.route("/create/idea/", methods=["GET", "POST"])
@login_required
def create():
    if flask_request.method == 'POST':
        current_app.logger.info("HEAR ME OUT")
        print("Hear me out")
        print("HEAR m3 OUT", flush=True)
        step = flask_request.form.get("step")

        if step == "step-1":
            current_app.logger.info("STEP 1...")

            handle = flask_request.form.get("handle")
            name = flask_request.form.get("name")
            description = flask_request.form.get("description")


            show_location = int(flask_request.form.get("show-location"))
            lat = flask_request.form.get("lat")
            lng = flask_request.form.get("lng")

            result = funcs.verify_credentials(handle=handle,name=name,description=description,show_location=show_location,lat=lat,lng=lng)
            if result:
                return result
            abi = funcs.get_abi()
            bytecode = funcs.get_bytecode()

            return json.dumps({'status': 'success', "abi":abi, "bytecode":bytecode})

        elif step == "step-2":
            current_app.logger.info("STEP 2")
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

            tx_hash = flask_request.form.get("tx");

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

            current_app.logger.info("testing code")
            # Wait for transaction to be mined...
            print(tx_hash)
            receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            deploy_data = w3.eth.getTransaction(tx_hash).input[2:-64] # remove 0x and argument data

            print(f"Receipt Address {receipt.contractAddress}")
            current_app.logger.info(f"IDEA ADDRESS: {receipt.contractAddress}")

            original_code = funcs.get_bytecode()
            if not receipt.contractAddress or deploy_data != original_code:
                return json.dumps({'status': 'Deployment did not go through!'})
            idea.address = receipt.contractAddress
            idea.block = receipt.blockNumber
        current_app.logger.info("UNPUSHED IDEA CREATED")
        db.session.add(idea)
        current_user.register_wallet(receipt["from"])
        # FINISH
        db.session.commit()
        current_app.logger.info("IDEA MOTHERFUCKING PUSHED")
        return json.dumps({'status': 'success', 'handle': handle})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profile/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/idea/<handle>/", methods=["GET", "POST"])
@ bp.route("/€<handle>/", methods=["GET", "POST"])
def idea(handle):
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    #if not idea or (not idea.public and not current_user in idea.group.members) and not current_user in idea.viewers:
        #abort(404)
    return render_template("idea/profile.html", idea=idea, navbar=True, background=True, size="medium", models=models)


@ bp.route("/idea/<handle>/edit/", methods=["GET", "POST"])
@ bp.route("/$<handle>/edit/", methods=["GET", "POST"])
@login_required
def edit(handle):
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

        db.session.commit()
        return json.dumps({'status': 'success', 'handle': handle})
    return render_template("idea/profile.html", idea=idea, background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/idea/<handle>/members/", methods=["GET"])
@ bp.route("/€<handle>/members/", methods=["GET"])
@login_required
def add_members(handle):
    if not handle:
        abort(404)
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    if not idea:
        abort(404)

    return render_template("idea/profile.html", idea=idea, background=True, navbar=True, size="medium", noscroll=True)


@ bp.route("/idea/<handle>/photo/", methods=["GET"])
@ bp.route("/€<handle>/photo/", methods=["GET"])
def photo(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    return render_template("idea/profile.html", idea=idea, noscroll=True, background=True, navbar=True, size="medium")


@ bp.route("/idea/<handle>/timeline/", methods=["GET"])
@ bp.route("/€<handle>/timeline/", methods=["GET"])
def timeline(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    return render_template("idea/profile.html", idea=idea, noscroll=True, background=True, navbar=True, size="medium")


@ bp.route("/idea/<handle>/update/timeline/", methods=["POST"])
@ bp.route("/€<handle>/update/timeline/", methods=["POST"])
def update_timeline(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    idea.update_timeline()
    db.session.commit()
    return json.dumps({'status': 'success'})


@bp.route("/idea/<handle>/get/timeline/", methods=["GET"])
@bp.route("/€<handle>/get/timeline/", methods=["GET"])
def get_timeline(handle):
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    return render_template("idea/timeline.html", idea=idea)


@ bp.route("/idea/<handle>/ownership/", methods=["GET"])
@ bp.route("/€<handle>/ownership/", methods=["GET"])
def ownership(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    return render_template("idea/profile.html", idea=idea, noscroll=True, background=True, navbar=True, size="medium")

@ bp.route("/idea/<handle>/update/ownership/", methods=["POST"])
@ bp.route("/€<handle>/update/ownership/", methods=["POST"])
def update_ownership(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    idea.update_ownership()
    db.session.commit()
    return json.dumps({'status': 'success'})

@bp.route("/idea/<handle>/get/ownership/", methods=["GET"])
@bp.route("/€<handle>/get/ownership/", methods=["GET"])
def get_ownership(handle):
    idea = models.Idea.query.filter_by(handle=handle).first_or_404()
    return render_template("idea/load-ownership-chart.html", idea=idea)

@ bp.route("/idea/<handle>/structure/", methods=["GET"])
@ bp.route("/€<handle>/structure/", methods=["GET"])
def structure(handle):
    idea = models.Idea.query.filter_by(handle=handle).first()
    if not idea:
        abort(404)
    return render_template("idea/profile.html", idea=idea, noscroll=True, background=True, navbar=True, size="medium")

