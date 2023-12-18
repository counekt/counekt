import logging
from logging.handlers import SMTPHandler, RotatingFileHandler
import os
from flask import Flask, request
from app.config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_migrate import Migrate
from geopy import Nominatim
from flask_mail import Mail
import boto3
from app.query import CustomQuery
import eth_abi
from web3 import Web3
from app.etherscan import Etherscan

w3 = Web3(Web3.HTTPProvider(Config.WEB3_NETWORK+Config.ALCHEMY_KEY))
etherscan = Etherscan(Config.ETHERSCAN_API_KEY,server=Config.ETHEREUM_SERVER)
geolocator = Nominatim(user_agent="frederik.w.l.christoffersen@gmail.com")
db = SQLAlchemy(query_class=CustomQuery)
migrate = Migrate()
mail = Mail()
login = LoginManager()
login.login_view = 'auth.login'
login.login_message = 'Please log in to access this page.'


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    db.init_app(app)
    migrate.init_app(app, db)
    login.init_app(app)
    mail.init_app(app)

    app.boto_session = boto3.Session(
        aws_access_key_id=app.config["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=app.config["AWS_SECRET_KEY"]
    )

    from app.routes.index import bp as index_bp
    from app.routes.map import bp as map_bp
    from app.routes.auth import bp as auth_bp
    from app.routes.api import bp as api_bp
    from app.routes.errors import bp as errors_bp
    from app.routes.profile import bp as profile_bp
    from app.routes.comms import bp as comms_bp
    from app.routes.erc360 import bp as erc360_bp

    app.register_blueprint(index_bp)
    app.register_blueprint(map_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(api_bp)
    app.register_blueprint(errors_bp)
    app.register_blueprint(profile_bp)
    app.register_blueprint(comms_bp)
    app.register_blueprint(erc360_bp)

    # ... no changes to blueprint registration
    if not app.debug and not app.testing:
        if app.config['MAIL_SERVER']:
            auth = None
        if app.config['MAIL_USERNAME'] or app.config['MAIL_PASSWORD']:
            auth = (app.config['MAIL_USERNAME'], app.config['MAIL_PASSWORD'])
        secure = None
        if app.config['MAIL_USE_TLS']:
            secure = ()
        mail_handler = SMTPHandler(
            mailhost=(app.config['MAIL_SERVER'], app.config['MAIL_PORT']),
            fromaddr='no-reply@' + app.config['MAIL_SERVER'],
            toaddrs=app.config['ADMINS'], subject='Counekt Failure',
            credentials=auth, secure=secure)
        mail_handler.setLevel(logging.ERROR)
        app.logger.addHandler(mail_handler)
        # ... no changes to logging setup
        if app.config['LOG_TO_STDOUT']:
            stream_handler = logging.StreamHandler()
            stream_handler.setLevel(logging.INFO)
            app.logger.addHandler(stream_handler)
        else:
            if not os.path.exists('logs'):
                os.mkdir('logs')
            file_handler = RotatingFileHandler('logs/counekt.log',
                                               maxBytes=10240, backupCount=10)
            file_handler.setFormatter(logging.Formatter(
                '%(asctime)s %(levelname)s: %(message)s '
                '[in %(pathname)s:%(lineno)d]'))
            file_handler.setLevel(logging.INFO)
            app.logger.addHandler(file_handler)

        app.logger.setLevel(logging.INFO)
        app.logger.info('Counekt startup')

    return app
