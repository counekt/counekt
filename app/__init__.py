import logging
from logging.handlers import SMTPHandler, RotatingFileHandler
import os
from flask import Flask, request
from app.config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_migrate import Migrate
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property
from sqlalchemy import func
from geopy import Nominatim
import airbnb

airbnb_api = airbnb.Api(randomize=True)
geolocator = Nominatim(user_agent="myGeocoder")
db = SQLAlchemy()
migrate = Migrate()


login = LoginManager()
login.login_view = 'main.login'
login.login_message = 'Please log in to access this page.'



def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    db.init_app(app)
    migrate.init_app(app, db)

    from app.main import bp as main_bp
    app.register_blueprint(main_bp)

    # ... no changes to blueprint registration

    if not app.debug and not app.testing:
        # ... no changes to logging setup
        if app.config['LOG_TO_STDOUT']:
            stream_handler = logging.StreamHandler()
            stream_handler.setLevel(logging.INFO)
            app.logger.addHandler(stream_handler)
        else:
            if not os.path.exists('logs'):
                os.mkdir('logs')
            file_handler = RotatingFileHandler('logs/deanonymizer.log',
                                               maxBytes=10240, backupCount=10)
            file_handler.setFormatter(logging.Formatter(
                '%(asctime)s %(levelname)s: %(message)s '
                '[in %(pathname)s:%(lineno)d]'))
            file_handler.setLevel(logging.INFO)
            app.logger.addHandler(file_handler)

        app.logger.setLevel(logging.INFO)
        app.logger.info('Deanonymizer startup')

    return app


from app import models
