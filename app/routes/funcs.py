from app.funcs import *
from flask import request

def redirectIfHeroku():
	if request.headers['Host'] == 'counekt.herokuapp.com':
		pass
		#return abort(301)
