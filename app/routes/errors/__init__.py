from flask import Blueprint

bp = Blueprint('errors', __name__)

from app.routes.errors import handlers
