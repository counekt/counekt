from flask import render_template, request
from app import db
from app.errors import bp
from app.errors.handlers import wants_json_response
from app.api.errors import error_response as api_error_response


def token_is_expired_error(token):
    if wants_json_response():
        return api_error_response(410, message=f"Token Expired: {token}\nThe specified token has either expired or is invalid.")
    return render_template('errors/token-is-expired.html', token=token, navbar=True, frame=True), 410
