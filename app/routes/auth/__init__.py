from flask import Blueprint
bp = Blueprint('auth', __name__)

from app.routes.auth import routes
