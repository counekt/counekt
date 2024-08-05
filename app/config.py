from os import getenv, path
from dotenv import load_dotenv
import boto3
from flask import url_for

appdir = path.abspath(path.dirname(__file__))

load_dotenv(path.join(appdir, '.env'))

class Config(object):
    SECRET_KEY = getenv("SECRET_KEY") or "you-will-never-guess"
    SQLALCHEMY_DATABASE_URI = getenv("DATABASE_URL")
    """SQLALCHEMY_DATABASE_URI = "postgresql://{dbuser}:{dbpass}@{dbhost}/{dbname}".format(
        dbuser=getenv("DBUSER"),
        dbpass=getenv("DBPASS"),
        dbhost=getenv("DBHOST"),
        dbname=getenv("DBNAME"))
    """
    LOG_TO_STDOUT = getenv('LOG_TO_STDOUT')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    PERMANENT_SESSION_LIFETIME = True
    AVAILABLE_SKILLS = ["Marketing", "Writing", "Photography",
                        "Videography", "Photo Editing", "Film Editing",
                        "Music Production", "Accounting", "Sales",
                        "Design", "Law", "Investing", "Software", "Acting"]
    AVAILABLE_SEXES = ["Male", "Female"]
    SKILL_ASPECTS = {"Marketing": {"background-color": "#3eafaf", "color": "white"}, "Writing": {"background-color": "#bc903d", "color": "white"}, "Photography": {"background-color": "#8c4c42", "color": "white"},
                     "Videography": {"background-color": "#413422", "color": "white"}, "Photo Editing": {"background-color": "#3d5115", "color": "white"}, "Film Editing": {"background-color": "#431512", "color": "white"},
                     "Music Production": {"background-color": "#025d57", "color": "white"}, "Accounting": {"background-color": "#1d3d59", "color": "white"}, "Sales": {"background-color": "#0b4e88", "color": "white"},
                     "Design": {"background-color": "#eca219", "color": "white"}, "Law": {"background-color": "#001a49", "color": "white"}, "Investing": {"background-color": "#01c690", "color": "white"}, "Software": {"background-color": "#0086d4", "color": "white"}, "Acting": {"background-color": "#d3021c", "color": "white"}}
    MAIL_SERVER = getenv('MAIL_SERVER')
    MAIL_PORT = int(getenv('MAIL_PORT') or 25)
    MAIL_USE_TLS = getenv('MAIL_USE_TLS') is not None
    MAIL_USERNAME = getenv('MAIL_USERNAME')
    MAIL_PASSWORD = getenv('MAIL_PASSWORD')
    AUTH_EXPIRES_IN = 6000
    ADMINS = ['frederik.w.l.christoffersen@gmail.com']
    BUCKET = getenv('BUCKET')
    AWS_ACCESS_KEY_ID = getenv("AWS_ACCESS_KEY_ID")
    AWS_SECRET_KEY = getenv("AWS_SECRET_KEY")
    SQLALCHEMY_POOL_SIZE=25
    ALCHEMY_KEY = getenv("ALCHEMY_KEY")
    WEB3_NETWORK = "https://eth-sepolia.g.alchemy.com/v2/"
    ETHERSCAN_API_KEY = "6DEHSP7NWYFR93NM8X3D456M1FCV3362YK"
    ETHEREUM_SERVER = "sepolia"
    ERC360_PATH = path.join(appdir,'static','solidity','build','contracts','ERC360Corporatizable.json')