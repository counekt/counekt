from flask import render_template, request
from app import db
from app.routes.errors import bp
from app.routes.api.errors import error_response as api_error_response


def wants_json_response():
    return request.accept_mimetypes['application/json'] >= \
        request.accept_mimetypes['text/html']


@bp.errorhandler(404)
def not_found_error(error):
    if wants_json_response():
        return api_error_response(404)
    return render_template('errors/404.html', navbar=True, frame=True), 404


@bp.errorhandler(410)
def gone_error(error):
    if wants_json_response():
        return api_error_response(410)
    return render_template('errors/410.html', navbar=True, frame=True), 410


@bp.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    if wants_json_response():
        return api_error_response(500)
    return render_template('errors/500.html', navbar=True, frame=True), 500
