# -*- coding: utf-8 -*-
from flask import redirect, url_for, render_template, abort, request, current_app
from app import db, models
import app.routes.map.funcs as funcs
import json
import re
import math
from datetime import date
from requests import HTTPError
from app.routes.marketplace import bp

# ======== Routing =========================================================== #

# -------- Home page ---------------------------------------------------------- #

@bp.route("/market/")
@bp.route("/marketplace/", methods=['GET', 'POST'])
def marketplace():
    return render_template("marketplace.html", background=True, navbar=True)

