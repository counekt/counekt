from flask import Blueprint
bp = Blueprint('profiles', __name__)

from app.profiles import routes
