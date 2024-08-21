from app.funcs import *
from app import db, models, w3
from flask import request as flask_request
import json

def verify_credentials(symbol,name,show_location,lat,lng):
	symbol = flask_request.form.get("symbol")
	name = flask_request.form.get("name")
	description = flask_request.form.get("description")

	show_location = int(flask_request.form.get("show-location"))
	lat = flask_request.form.get("lat")
	lng = flask_request.form.get("lng")

	if not symbol:
		return json.dumps({'status': 'Symbol must be filled in', 'box_id': 'symbol'})

	if not name:
		return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

	if len(description.strip()) > 160:
		return json.dumps({'status': 'Your ERC360\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

	if show_location:

		if not lat or not lng:
			return json.dumps({'status': 'Coordinates must be filled in, if you want to show your ERC360\'s location and or be visible on the map', 'box_id': 'location'})

		location = reverse_geocode([lat, lng])
		if not location:
			return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})