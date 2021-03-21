from flask import current_app
from app import geolocator
from geopy.exc import GeocoderTimedOut
from geopy.extra.rate_limiter import RateLimiter
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import errno
from threading import Thread
import concurrent.futures
from botocore.exceptions import EndpointConnectionError
from pathlib import Path
import os


def geocode(address, attempt=1, max_attempts=5):
    try:
        return RateLimiter(geolocator.geocode, min_delay_seconds=1)(address)
    except GeocoderTimedOut:
        if attempt <= max_attempts:
            return geocode(address, attempt=attempt + 1)
        raise


def reverse_geocode(coordinates, attempt=1, max_attempts=5, languages=["en"], zoom=14):
    try:
        return RateLimiter(geolocator.reverse, min_delay_seconds=1)(coordinates, language=languages, zoom=zoom)
    except GeocoderTimedOut:
        if attempt <= max_attempts:
            return reverse_geocode(coordinates, attempt=attempt + 1, languages=languages, zoom=zoom)
        raise


def shorten_addr(location):
    addr = location.raw["address"]
    display = addr.get("country")
    print(addr)
    if addr.get("city"):
        display += ", " + addr.get("city")
    elif addr.get("town"):
        display += ", " + addr.get("town")
    elif addr.get("state"):
        display += ", " + addr.get("state")
    elif addr.get("county"):
        display += ", " + addr.get("county")
    elif addr.get("borough"):
        display += ", " + addr.get("borough")
    elif addr.get("suburb"):
        display += ", " + addr.get("suburb")
    elif addr.get("village"):
        display += ", " + addr.get("village")
    elif addr.get("hamlet"):
        display += ", " + addr.get("hamlet")

    return display


def get_age(birthdate, today=date.today()):
    return today.year - birthdate.year - ((today.month, today.day) < (birthdate.month, birthdate.day))


def is_expired(birth, now=datetime.now(), expires_in=600):
    return birth < now - relativedelta(seconds=expires_in)


def is_older_than(date_of_birth, age, today=datetime.today()):
    return date_of_birth <= today - relativedelta(years=age)


def is_younger_than(date_of_birth, age, today=datetime.today()):
    return date_of_birth >= today - relativedelta(years=age)


def join_parts(*parts):
    return '/'.join(p.strip('/') for p in parts)


def upload_file(file_path, object_name, sync=False):
    """
    Function to upload a file to an S3 bucket
    """

    if sync:
        try:
            s3_client = current_app.boto_session.client('s3')
            response = s3_client.upload_file(file_path, current_app.config["BUCKET"], object_name)
            return response
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)
    else:
        with concurrent.futures.ThreadPoolExecutor() as executor:
            try:
                response = executor.submit(upload_async_file, current_app._get_current_object(), file_path, object_name).result()
                return response
            except EndpointConnectionError as e:
                current_app.logger.error(e.message)


def delete_file(file_path, sync=False):
    """
    Function to delete a file from an S3 bucket
    """
    if sync:
        try:
            s3 = current_app.boto_session.client('s3')
            s3.delete_object(Bucket=current_app.config["BUCKET"], Key=file_path)
            return True
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)
    else:
        try:
            Thread(target=delete_async_file,
                   args=(current_app._get_current_object(), file_path)).start()
            return True
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)


def download_file(file_path, output_path, sync=False):
    """
    Function to download a given file from an S3 bucke
    """
    if sync:
        try:
            s3 = current_app.boto_session.resource('s3')
            s3.Bucket(current_app.config["BUCKET"]).download_file(file_path, output_path)
            return True
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)
    else:
        try:
            Thread(target=download_async_file,
                   args=(current_app._get_current_object(), file_path, output_path)).start()
            return True
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)


def list_files(folder_path, sync=False):
    """
    Function to list files in a given folder from an S3 bucket
    """
    if sync:
        try:
            s3 = current_app.boto_session.client('s3')
            folder = s3.list_objects_v2(Bucket=current_app.config["BUCKET"], Prefix=folder_path)
            if folder.get("Contents"):
                file_list = [Path(file["Key"]).parts[-1] for file in folder["Contents"]]
                return file_list
            else:
                return False
        except EndpointConnectionError as e:
            current_app.logger.error(e.message)
    else:
        with concurrent.futures.ThreadPoolExecutor() as executor:
            try:
                response = executor.submit(list_async_files, current_app._get_current_object(), folder_path).result()
                return response
            except EndpointConnectionError as e:
                current_app.logger.error(e.message)
                return False


"""
       __________________
      ///////////////////
     //ASYNC FUNCTIONS//
    ///////////////////
    ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
"""


def upload_async_file(app, file_path, object_name):
    with app.app_context():
        s3_client = current_app.boto_session.client('s3')
        response = s3_client.upload_file(file_path, current_app.config["BUCKET"], object_name)
        return response


def delete_async_file(app, file_path):
    with app.app_context():
        s3 = current_app.boto_session.client('s3')
        s3.delete_object(Bucket=current_app.config["BUCKET"], Key=file_path)


def download_async_file(app, file_path, output_path):
    with app.app_context():
        s3 = current_app.boto_session.resource('s3')
        s3.Bucket(current_app.config["BUCKET"]).download_file(file_path, output_path)


def list_async_files(app, folder_path):
    with app.app_context():
        s3 = current_app.boto_session.client('s3')
        folder = s3.list_objects_v2(Bucket=current_app.config["BUCKET"], Prefix=folder_path)
        if folder.get("Contents"):
            file_list = [Path(file["Key"]).parts[-1] for file in folder["Contents"]]
            return file_list
        else:
            return False


"""
def src_for(file_path):
    s3 = current_app.boto_session.resource('s3')
    bucket = s3.Bucket(current_app.config["BUCKET"])
    location = boto_session.client('s3').get_bucket_location(Bucket=current_app.config["BUCKET"])['LocationConstraint']
    url = "https://s3-%s.amazonaws.com/%s/%s" % (location, current_app.config["BUCKET"], file_path)
    return url
"""


def silent_local_remove(file_path):
    try:
        os.remove(file_path)
    except OSError as e:
        if e.eerno != errno.ENOENT:  # errno.ENOENT = no such file or directory
            raise  # re-raise exception if a different error occurred
