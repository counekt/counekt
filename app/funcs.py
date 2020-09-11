from app import geolocator
from geopy.exc import GeocoderTimedOut
from datetime import date
from dateutil.relativedelta import relativedelta


def geocode(address, attempt=1, max_attempts=5):
    try:
        return geolocator.geocode(address)
    except GeocoderTimedOut:
        if attempt <= max_attempts:
            return geocode(address, attempt=attempt + 1)
        raise


def get_age(date_of_birth):
    today = date.today()
    return today.year - date_of_birth.year - ((today.month, today.day) < (date_of_birth.month, date_of_birth.day))


def is_older(date_of_birth, age):
    today = date.today()
    return date_of_birth <= today - relativedelta(years=age)


def is_younger(date_of_birth, age):
    today = date.today()
    return date_of_birth >= today - relativedelta(years=age)
