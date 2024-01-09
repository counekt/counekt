from flask import current_app, abort
from app import geolocator, w3
from geopy.exc import GeocoderTimedOut
from geopy.extra.rate_limiter import RateLimiter
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import errno
from threading import Thread
import concurrent.futures
from botocore import UNSIGNED
from botocore.client import Config
from botocore.exceptions import EndpointConnectionError
from pathlib import Path
import os
import json
from eth_abi import abi

def decode_transaction_payload(t):
    data = bytearray.fromhex(t["input"][2:])[4:] # we don't include the function selector
    if t["methodId"] == '0x60806040': # on creation
        return t
    elif t["methodId"] == '0x': # on simple receipt
        return t
    elif t["methodId"] == '0x8ab73cf9': # setPermit(address,bytes32,bool)
        account,permit,status = abi.decode_abi(["address","bytes32","bool"],data)
        return t | {"args": {"account":w3.toChecksumAddress(account),"permit":permit.hex(),"status":status}}
    elif t["methodId"] == '0x9a9abf85': # setPermitParent(bytes32,bytes32)
        permit, parent = abi.decode_abi(["bytes32","bytes32"],data)
        return t | {"args": {"permit":permit.hex(),"parent":parent.hex()}}
    elif t["methodId"] == '0x40c10f19': # mint(address,uint256)
        account, amount = abi.decode_abi(["address","uint256"],data)
        return t | {"args": {"account":w3.toChecksumAddress(account),"amount":amount}}
    elif t["methodId"] == '0x873fdde7': # issueDividend(bytes32,address,uint256)
        bank, token, amount = abi.decode_abi(["bytes32","address","uint256"],data)
        return t | {"args": {"bank":bank.hex(),"token":w3.toChecksumAddress(token),"amount":amount}}
    elif t["methodId"] == '0x3598f3f3': # issueVote(bytes4[],bytes[],uint256)
        sigs, args, duration = abi.decode_abi(["bytes4[]","bytes[]","uint256"],data)
        return t | {"args": {"sigs":[s.hex() for s in sigs],"args":[a.hex() for a in args],"duration":duration}}
    elif t["methodId"] == '0x74c8df12': # implementResolution(uint256)
        voteId = abi.decode_abi(["uint256"],data)
        return t | {"args": {"voteId":voteId}}
    elif t["methodId"] == '0x3b51634f': # callExternal(address,bytes4,bytes,uint256,bytes32)
        ext,sig,args,value,bank = abi.decode_abi(["address","bytes4","bytes","uint256","bytes32"],data)
        return t | {"args": {"ext":w3.toChecksumAddress(ext),"sig":sig.hex(),"args":args.hex(),"value":value,"bank":bank.hex()}}
    elif t["methodId"] == '0x23a7c49b': # setExternalCallPermit(address,bytes4,bytes32)
        ext,sig,permit = abi.decode_abi(["address","bytes4","bytes32"],data)
        return t | {"args": {"ext":w3.toChecksumAddress(ext),"sig":sig.hex(),"permit":permit.hex()}}
    elif t["methodId"] == "0x7ab1f504": # transferFundsFromBank(bytes32,address,address,uint256)
        fromBank, to, token, amount = abi.decode_abi(["bytes32","address","address","uint256"],data)
        return t | {"args": {"fromBank":fromBank.hex(),"token":w3.toChecksumAddress(token),"amount":amount,"to":w3.toChecksumAddress(to)}}
    elif t["methodId"] == '0x3fb3a2d7': # moveFunds(bytes32,bytes32,address,uint256)
        fromBank,toBank,token,amount = abi.decode_abi(["bytes32","bytes32","address","uint256"],data)
        return t | {"args": {"fromBank":fromBank.hex(),"toBank":toBank.hex(),"token":w3.toChecksumAddress(token),"amount":amount,"to":w3.toChecksumAddress(to)}}
    else:
        return t


def get_deployed_bytecode():
    with open("solidity/build/contracts/ERC360Corporatizable.json","r") as json_file:
        json_data = json.load(json_file)
        return json_data["deployedBytecode"]

def get_bytecode():
    with open("solidity/build/contracts/ERC360Corporatizable.json","r") as json_file:
        json_data = json.load(json_file)
        return json_data["bytecode"]

def get_abi():
    with open("solidity/build/contracts/ERC360Corporatizable.json","r") as json_file:
        json_data = json.load(json_file)
        return json_data["abi"]

def contract_has_method(bytecode, signature):
    function_signature = w3.eth.abi.encodeFunctionSignature(signature)
    # remove "0x" prefixed in 0x<4bytes-selector>
    return bytecode.index(functionSignature[2:]) > 0;

def returnifelse(primary,bottleneck,secondary):
    return primary if bottleneck else secondary

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
    addr = location.raw.get("address",location.raw.get("display_name"))
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
            s3_client = get_s3_client()
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
            s3 = get_s3_client()
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
            s3 = current_app.boto_session.resource('s3', endpoint_url='https://s3.nl-1.wasabisys.com')
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

def generate_presigned_url(file_path):
    s3 = current_app.boto_session.client('s3', config=Config(signature_version=UNSIGNED),endpoint_url='https://s3.nl-1.wasabisys.com')
    url = s3.generate_presigned_url('get_object',Params={'Bucket': current_app.config["BUCKET"],'Key': file_path},ExpiresIn=0)
    return url

def list_files(folder_path, sync=False):
    """
    Function to list files in a given folder from an S3 bucket
    """
    if sync:
        try:
            s3 = get_s3_client()
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
        s3_client = get_s3_client()
        response = s3_client.upload_file(file_path, current_app.config["BUCKET"], object_name)
        return response


def delete_async_file(app, file_path):
    with app.app_context():
        s3 = get_s3_client()
        s3.delete_object(Bucket=current_app.config["BUCKET"], Key=file_path)


def download_async_file(app, file_path, output_path):
    with app.app_context():
        s3 = current_app.boto_session.resource('s3',endpoint_url="https://s3.nl-1.wasabisys.com")
        s3.Bucket(current_app.config["BUCKET"]).download_file(file_path, output_path)


def list_async_files(app, folder_path):
    with app.app_context():
        s3 = get_s3_client()
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
    except FileNotFoundError: # If not because it does not exist
        pass
    # exception if a different error occurred

def get_s3_client():
    return current_app.boto_session.client('s3',endpoint_url='https://s3.nl-1.wasabisys.com')