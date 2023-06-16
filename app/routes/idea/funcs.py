from app.funcs import *
from app import db, models, w3
from flask import request as flask_request
import json
from eth_abi import abi

def decode_event(e):
	if e["args"]["fName"] == "cB":
		bankName, bankAdmin = abi.decode_abi(["string","address"])
		return {"fName":fName, "bankName":bankName,"bankAdmin":bankAdmin, "by":e["args"]["by"]}
	if e["args"]["fName"] == "sP":
		permitName, newState = abi.decode_abi(["string","uint8"])
		return {"fName":fName, "permitName":permitName,"newState":newState, "by":e["args"]["by"]}
	"""NOTE: FINISH REST"""

def verify_credentials(handle,name,description,show_location,lat,lng):
	handle = flask_request.form.get("handle")
	name = flask_request.form.get("name")
	description = flask_request.form.get("description")

	show_location = int(flask_request.form.get("show-location"))
	lat = flask_request.form.get("lat")
	lng = flask_request.form.get("lng")

	if not handle:
		return json.dumps({'status': 'Handle must be filled in', 'box_id': 'handle'})

	if not name:
		return json.dumps({'status': 'Name must be filled in', 'box_id': 'name'})

	if not description:
		return json.dumps({'status': 'Description must be filled in', 'box_id': 'description'})

	if not models.Idea.query.filter_by(handle=handle).first() is None:
		return json.dumps({'status': 'Handle already taken', 'box_id': 'handle'})

	if len(description.strip()) > 160:
		return json.dumps({'status': 'Your Idea\'s description can\'t exceed a length of 160 characters', 'box_id': 'description'})

	if show_location:
		idea = models.Idea(handle=handle.strip(), name=name.strip(), description=description.strip(), members=[current_user])

		if not lat or not lng:
			return json.dumps({'status': 'Coordinates must be filled in, if you want to show your Idea\'s location and or be visible on the map', 'box_id': 'location'})

		location = funcs.reverse_geocode([lat, lng])
		if not location:
			return json.dumps({'status': 'Invalid coordinates', 'box_id': 'location'})

