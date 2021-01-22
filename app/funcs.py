from app import geolocator
from geopy.exc import GeocoderTimedOut
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
from flask import current_app


def geocode(address, attempt=1, max_attempts=5):
    try:
        return geolocator.geocode(address)
    except GeocoderTimedOut:
        if attempt <= max_attempts:
            return geocode(address, attempt=attempt + 1)
        raise


def get_age(birthdate, today=date.today()):
    return today.year - birthdate.year - ((today.month, today.day) < (birthdate.month, birthdate.day))


def is_expired(birth, now=datetime.now(), expires_in=600):
    return birth < now - relativedelta(seconds=expires_in)


def is_older_than(date_of_birth, age, today=datetime.today()):
    return date_of_birth <= today - relativedelta(years=age)


def is_younger_than(date_of_birth, age, today=datetime.today()):
    return date_of_birth >= today - relativedelta(years=age)
