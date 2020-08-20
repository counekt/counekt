# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request
from app import db
from app.main.funcs import geocode, get_listing_info
import json
import folium
import re
import math
from datetime import date
from requests import HTTPError
from app.main import bp
# ======== Routing =========================================================== #

# -------- Home page ---------------------------------------------------------- #


@bp.route("/")
@bp.route("/main/")
@bp.route("/main/<listing_id>/")
@bp.route("/<listing_id>/", methods=['GET', 'POST'])
def main(listing_id=None):
    if request.method == 'POST':
        listing_id = request.form.get("listing-id")
        print(f"id:{listing_id}:")
        if not listing_id:
            return json.dumps({'status': 'Oops, you forgot to enter an id'})

        if not listing_id.isdigit():
            return json.dumps({'status': 'Oops, you entered an invalid id'})

        try:
            info = get_listing_info(listing_id)
        except HTTPError as e:
            if e.response.status_code == 403:
                return json.dumps({'status': 'Oops, you entered an invalid id'})
            else:
                raise

        return json.dumps({'status': 'Successfully deanonymized', 'info': info})

    return render_template("main.html", listing_id=listing_id)


@bp.route("/about/", methods=['GET'])
def about():
    return render_template("about.html")


@bp.route("/help/", methods=['GET'])
def help():
    return render_template("help.html")


@bp.route("/settings/", methods=['GET'])
def settings():
    return render_template("settings.html")
