from flask import render_template, request
from app import db
from app.routes.errors import bp
from app.routes.errors.handlers import wants_json_response
from app.routes.api.errors import error_response as api_error_response
from flask import current_app


def auth_token_is_expired_error(auth_token):
    if wants_json_response():
        return api_error_response(410, message=f"Token Expired: {auth_token}\nThe specified authentication token has either expired or is invalid.")
    return render_template('errors/auth-token-is-expired.html', auth_token=auth_token, navbar=True, frame=True), 410


def email_not_sent_error(e):
    current_app.logger.error(e)
    if wants_json_response():
        return api_error_response(500, message=f"Email Not Sent: The email service failed to send the email. The administrators have been notified. Sorry for the inconvenience!")
