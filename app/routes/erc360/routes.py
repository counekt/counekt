# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, current_app
from flask import request as flask_request
from app import db, models, w3
import app.routes.erc360.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.erc360 import bp
from flask_login import LoginManager, current_user, login_user, logout_user, login_required
import app.models as models
from eth_abi import abi

global erc360

@ bp.route("/erc360/<address>/", methods=["GET", "POST"])
@ bp.route("/€<address>/", methods=["GET", "POST"])
def erc360(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/profile.html", erc360=e360, navbar=True, background=True, size="medium", models=models)


@ bp.route("/erc360/<address>/timeline/", methods=["GET"])
@ bp.route("/€<address>/timeline/", methods=["GET"])
def timeline(address):
    return erc360(address)

@ bp.route("/erc360/<address>/structure/", methods=["GET"])
@ bp.route("/€<address>/structure/", methods=["GET"])
def structure(address):
    return erc360(address)

@ bp.route("/erc360/<address>/deposit/", methods=["GET"])
@ bp.route("/€<address>/deposit/", methods=["GET"])
def deposit(address):
    return erc360(address)

@ bp.route("/erc360/<address>/transfer/", methods=["GET"])
@ bp.route("/€<address>/transfer/", methods=["GET"])
def transfer(address):
    return erc360(address)

@ bp.route("/erc360/<address>/assign/", methods=["GET"])
@ bp.route("/€<address>/assign/", methods=["GET"])
def assign(address):
    return erc360(address)

@ bp.route("/erc360/<address>/revoke/", methods=["GET"])
@ bp.route("/€<address>/revoke/", methods=["GET"])
def revoke(address):
    return erc360(address)

@ bp.route("/erc360/<address>/claim/", methods=["GET"])
@ bp.route("/€<address>/claim/", methods=["GET"])
def claim(address):
    return erc360(address)

@ bp.route("/erc360/<address>/distribute/", methods=["GET"])
@ bp.route("/€<address>/distribute/", methods=["GET"])
def distribute(address):
    return erc360(address)

@ bp.route("/erc360/<address>/vote/", methods=["GET"])
@ bp.route("/€<address>/vote/", methods=["GET"])
def vote(address):
    return erc360(address)

@ bp.route("/erc360/<address>/propose/", methods=["GET"])
@ bp.route("/€<address>/propose/", methods=["GET"])
def propose(address):
    return erc360(address)

@ bp.route("/erc360/<address>/structure/banks/", methods=["GET"])
@ bp.route("/€<address>/structure/banks/", methods=["GET"])
def banks(address):
    return erc360(address)

@ bp.route("/erc360/<address>/structure/permits/", methods=["GET"])
@ bp.route("/€<address>/structure/permits/", methods=["GET"])
def permits(address):
    return erc360(address)

@ bp.route("/erc360/<address>/structure/dividends/", methods=["GET"])
@ bp.route("/€<address>/structure/dividends/", methods=["GET"])
def dividends(address):
    return erc360(address)

@ bp.route("/erc360/<address>/structure/referendums/", methods=["GET"])
@ bp.route("/€<address>/structure/referendums/", methods=["GET"])
def referendums(address):
    return erc360(address)

@ bp.route("/erc360/<address>/ownership/", methods=["GET"])
@ bp.route("/€<address>/ownership/", methods=["GET"])
def ownership(address):
    return erc360(address)

@bp.route("/erc360/<address>/mint/", methods=["GET","POST"])
@bp.route("/€<address>/mint/", methods=["GET","POST"])
def mint(address):
    if flask_request.method == 'POST':
        tx = flask_request.form.get("tx")
        receipt = w3.eth.waitForTransactionReceipt(tx)
        log = receipt.logs[0]
        print(f"Receipt: {receipt.contractAddress} != Address: {address}")
        print(f"Log: {log}")
        assert(log["address"] == address)
        account, amount = abi.decode_abi(["address","uint256"],bytes.fromhex(log["data"][2:]))
        print(account,amount)
        e360 = models.ERC360.query.filter_by(address=address).first()
        e360.update_ownership()
        return json.dumps({'status': 'success'})

    return erc360(address)

@ bp.route("/erc360/<address>/photo/", methods=["GET"])
@ bp.route("/€<address>/photo/", methods=["GET"])
def photo(address):
    return erc360(address)

@ bp.route("/erc360/<address>/update/timeline/", methods=["POST"])
@ bp.route("/€<address>/update/timeline/", methods=["POST"])
def update_timeline(address):
    e360 = models.ERC360.query.filter_by(address=address).first()
    if not e360:
        abort(404)
    e360.update_timeline()
    db.session.commit()
    return json.dumps({'status': 'success'})


@bp.route("/erc360/<address>/get/timeline/", methods=["GET"])
@bp.route("/€<address>/get/timeline/", methods=["GET"])
def get_timeline(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/timeline.html", erc360=e360, models=models)


@ bp.route("/erc360/<address>/update/ownership/", methods=["POST"])
@ bp.route("/€<address>/update/ownership/", methods=["POST"])
def update_ownership(address):
    e360 = models.ERC360.query.filter_by(address=address).first()
    if not e360:
        abort(404)
    e360.update_ownership()
    db.session.commit()
    return json.dumps({'status': 'success'})

@bp.route("/erc360/<address>/get/ownership/", methods=["GET"])
@bp.route("/€<address>/get/ownership/", methods=["GET"])
def get_ownership(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/ownership/load-ownership-chart.html", erc360=e360)

@ bp.route("/erc360/<address>/update/structure/", methods=["POST"])
@ bp.route("/€<address>/update/structure/", methods=["POST"])
def update_structure(address):
    e360 = models.ERC360.query.filter_by(address=address).first()
    if not erc360:
        abort(404)
    e360.update_structure()
    db.session.commit()
    return json.dumps({'status': 'success'})

@bp.route("/erc360/<address>/get/structure/", methods=["GET"])
@bp.route("/€<address>/get/structure/", methods=["GET"])
def get_structure(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/structure.html", erc360=e360,models=models)

@bp.route("/erc360/<address>/get/structure/bank/transfer/", methods=["GET"])
@bp.route("/€<address>/get/structure/bank/transfer/", methods=["GET"])
def get_transfer(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/structure/transfer.html", erc360=e360,models=models)

@bp.route("/erc360/<address>/get/edit/", methods=["GET"])
@bp.route("/€<address>/get/edit/", methods=["GET"])
def get_edit(address):
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    return render_template("erc360/edit.html", erc360=e360,models=models)

@ bp.route("/erc360/<address>/edit/", methods=["GET", "POST"])
@ bp.route("/€<address>/edit/", methods=["GET", "POST"])
@login_required
def edit(address):
    if not address:
        abort(404)
    e360 = models.ERC360.query.filter_by(address=address).first_or_404()
    if not e360:
        abort(404)
    if flask_request.method == 'POST':

        description = flask_request.form.get("description")

        public = bool(flask_request.form.get("public"))

        show_location = int(flask_request.form.get("show-location"))
        is_visible = int(bool(flask_request.form.get("visible")))
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")

        file = flask_request.files.get("photo")

        if len(description.strip()) > 160:
            return json.dumps({'status': 'Your corporatizable token\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

        e360.description = description.strip()
        e360.public = public

        if show_location:

            if not lat or not lng:
                return json.dumps({'status': 'Coordinates must be filled in, if you want to show the location of your corporatizable token or for it to be visible on the map', 'box_id': 'location'})

            location = funcs.reverse_geocode([lat, lng])
            if not location:
                return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
            e360.location.set(location=location)

            e360.show_location = True
            if is_visible:
                e360.is_visible = True
        else:
            e360.latitude = None
            e360.longitude = None
            e360.sin_rad_lat = None
            e360.cos_rad_lat = None
            e360.rad_lng = None
            e360.location_address = None
            e360.is_visible = False
            e360.show_location = False

        if file:
            e360.profile_photo.save(file=file)

        db.session.commit()
        return json.dumps({'status': 'success', 'address': address})
    return render_template("erc360/profile.html", erc360=e360, models=models, background=True, navbar=True, size="medium", noscroll=True)


@bp.route("/create/erc360/", methods=["GET", "POST"])
@login_required
def create():
    if flask_request.method == 'POST':
        step = flask_request.form.get("step")

        if step == "step-1":
            current_app.logger.info("STEP 1...")

            name = flask_request.form.get("name")
            symbol = flask_request.form.get("symbol")
            description = flask_request.form.get("description")


            show_location = int(flask_request.form.get("show-location"))
            lat = flask_request.form.get("lat")
            lng = flask_request.form.get("lng")

            result = funcs.verify_credentials(symbol=symbol,name=name,show_location=show_location,lat=lat,lng=lng)
            if result:
                return result
            abi = funcs.get_abi()
            bytecode = funcs.get_bytecode()

            return json.dumps({'status': 'success', "abi":abi, "bytecode":bytecode, "name":name, "symbol":symbol})

        elif step == "step-2":
            current_app.logger.info("STEP 2")

            name = flask_request.form.get("name")
            symbol = flask_request.form.get("symbol")
            description = flask_request.form.get("description")


            show_location = int(flask_request.form.get("show-location"))
            lat = flask_request.form.get("lat")
            lng = flask_request.form.get("lng")

            public = bool(flask_request.form.get("public"))
            is_visible = int(bool(flask_request.form.get("visible")))

            result = funcs.verify_credentials(symbol=symbol,name=name,show_location=show_location,lat=lat,lng=lng)
            if result:
                return result

            file = flask_request.files.get("photo")

            tx_hash = flask_request.form.get("tx");

            receipt = w3.eth.waitForTransactionReceipt(tx_hash)
            wallet = models.Wallet.get_or_register(address=receipt["from"],spender=current_user)
            e360 = models.ERC360(symbol=symbol, name=name, public=public, creator=wallet,address=receipt.contractAddress,block=receipt.blockNumber)
            if show_location:
                location = funcs.reverse_geocode([lat, lng])
                if not location:
                    return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})
                e360.location.set(location=location)

                e360.show_location = True
                if is_visible:
                    e360.is_visible = True
            else:
                e360.latitude = None
                e360.longitude = None
                e360.sin_rad_lat = None
                e360.cos_rad_lat = None
                e360.rad_lng = None
                e360.location_address = None
                e360.is_visible = False
                e360.show_location = False

            if file:
                e360.profile_photo.save(file=file)

            current_app.logger.info("testing code")
            # Wait for transaction to be mined...
            print(tx_hash)
            original_code = funcs.get_bytecode()
            deploy_data_raw = w3.eth.getTransaction(tx_hash).input # remove 0x and constructor data
            deploy_data = deploy_data_raw[2:][:len(original_code)]
            print(f"Receipt Address {receipt.contractAddress}")
            current_app.logger.info(f"ERC360 ADDRESS: {receipt.contractAddress}")

            if not receipt.contractAddress or deploy_data != original_code:
                return json.dumps({'status': 'Deployment did not go through!'})
        current_app.logger.info("UNPUSHED ERC360 CREATED")
        db.session.add(e360)
        current_user.register_wallet(receipt["from"])
        # FINISH
        db.session.commit()
        current_app.logger.info("ERC360 MOTHERFUCKING PUSHED")
        return json.dumps({'status': 'success', 'address': e360.address})
    skillrows = [current_user.skills.all()[i:i + 3] for i in range(0, len(current_user.skills.all()), 3)]
    return render_template("profile/user/profile.html", user=current_user, skillrows=skillrows, skill_aspects=current_app.config["SKILL_ASPECTS"], available_skills=current_app.config["AVAILABLE_SKILLS"], background=True, navbar=True, size="medium", noscroll=True)

@ bp.route("/erc360corporatizable/abi/", methods=["GET"])
@login_required
def get_abi():
    abi = funcs.get_abi()
    return json.dumps(abi)