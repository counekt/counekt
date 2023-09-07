from flask import Blueprint
bp = Blueprint('erc360', __name__)

from app.routes.erc360 import routes