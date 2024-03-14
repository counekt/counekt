from flask import Blueprint
bp = Blueprint('marketplace', __name__)

from app.routes.marketplace import routes
