from flask import Blueprint
bp = Blueprint('map', __name__)

from app.routes.map import routes, geography
