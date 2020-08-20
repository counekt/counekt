from app import geolocator, airbnb_api
from geopy.exc import GeocoderTimedOut
from PIL import Image
import requests
from io import BytesIO


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


def get_listing_info(listing_id):
    details = airbnb_api.get_listing_details(listing_id)
    filtered_details = {key: details["pdp_listing_detail"].get(key) for key in ["country_code", "country", "state", "city", "lat", "lng"]}
    filtered_details["first_name"] = details["pdp_listing_detail"]["primary_host"].get("first_name").split()[0]
    filtered_details["postal_code"] = geolocator.reverse((filtered_details["lat"], filtered_details["lng"])).raw['address']['postcode']

    return filtered_details
