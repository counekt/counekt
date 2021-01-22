from os import getenv, path
from dotenv import load_dotenv

basedir = path.abspath(path.dirname(__file__))

load_dotenv(path.join(basedir, '.env'))


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
                        "Videography", "Photo editing", "Film editing",
                        "Music producer", "Accountant", "Salesman",
                        "(X) designer", "Lawyer", "Investor", "Software", "Acting"]
    AVAILABLE_GENDERS = ["Male", "Female", "Other"]
    MAIL_SERVER = getenv('MAIL_SERVER')
    MAIL_PORT = int(getenv('MAIL_PORT') or 25)
    MAIL_USE_TLS = getenv('MAIL_USE_TLS') is not None
    MAIL_USERNAME = getenv('MAIL_USERNAME')
    MAIL_PASSWORD = getenv('MAIL_PASSWORD')
    AUTH_EXPIRES_IN = 6000
    ADMINS = ['frederik.w.l.christoffersen@gmail.com']
