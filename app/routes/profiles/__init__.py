from flask import Blueprint
bp = Blueprint('profiles', __name__)

from app.routes.profiles import routes
