from flask import Blueprint
bp = Blueprint('stats', __name__)
from app.routes.stats import routes