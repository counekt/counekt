from app import create_app, db
import app.models as models
from geopy import Nominatim


geolocator = Nominatim(user_agent="myGeocoder")


app = create_app()


@app.shell_context_processor
def make_shell_context():
    return {'db': db, "models": models, 'geolocator': geolocator}
