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
