from app.funcs import *
from flask import request

def redirectIfHeroku():
	if request.headers['Host'] == 'counekt.herokuapp.com':
		return abort(301)
