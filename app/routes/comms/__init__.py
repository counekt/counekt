from flask import Blueprint
bp = Blueprint('comms', __name__)

from app.routes.comms import routes
