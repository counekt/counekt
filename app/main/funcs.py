from app import geolocator
from geopy.exc import GeocoderTimedOut
import requests
from io import BytesIO
import math


def geocode(address, attempt=1, max_attempts=5):
    try:
        return geolocator.geocode(address)
    except GeocoderTimedOut:
        if attempt <= max_attempts:
            return geocode(address, attempt=attempt + 1)
        raise


def get_image_from(src):
    return Image.open(BytesIO(requests.get(src).content))


def join_parts(*parts):
    return '/'.join(p.strip('/') for p in parts)


def get_zoom_from_rad(r):
    return round(min(max(2, 16 - math.log2(r)), 13))
