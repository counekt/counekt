from flask import Blueprint
bp = Blueprint('idea', __name__)

from app.routes.idea import routes