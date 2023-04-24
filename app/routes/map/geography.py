import app.routes.map.funcs as funcs
from app.routes.map import bp

@ bp.route("/get/coordinates/", methods=["POST"])
def get_coordinates():
    if flask_request.method == 'POST':
        address = flask_request.form.get("address")
        location = funcs.geocode(address)
        location = funcs.reverse_geocode([location.latitude, location.longitude])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address':funcs.shorten_addr(location=location),'lat': location.latitude, 'lng': location.longitude})

@ bp.route("/get/address/", methods=["POST"])
def get_address():
    if flask_request.method == 'POST':
        lat = flask_request.form.get("lat")
        lng = flask_request.form.get("lng")
        location = funcs.reverse_geocode([lat, lng])
        if not location:
            return json.dumps({'status': 'Non-valid location'})
        return json.dumps({'status': 'success', 'address': location.address})
