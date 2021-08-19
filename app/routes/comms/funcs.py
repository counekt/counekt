from app.funcs import *
from urllib.parse import urlencode
from requests.models import PreparedRequest

req = PreparedRequest()

def edit_querystr(url, params):
	req.prepare_url(url, params)
	return req.url