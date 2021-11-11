from flask import Blueprint
bp = Blueprint('index', __name__)

from app.routes.index import routes