from app.funcs import *
from urllib.parse import urlencode
from requests.models import PreparedRequest

def edit_querystr(url, params):
	req = PreparedRequest()
	req.prepare_url(url, params)
	print(req.url)
	return req.url