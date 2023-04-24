from flask import Blueprint
bp = Blueprint('profile', __name__)

from app.routes.profile import routes
