from app import db
import app.funcs as funcs
import math

class LocationBase:
    address = db.Column(db.String)
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    sin_rad_lat = db.Column(db.Float)
    cos_rad_lat = db.Column(db.Float)
    rad_lng = db.Column(db.Float)
    show_location = db.Column(db.Boolean, default=False)
    is_visible = db.Column(db.Boolean, default=False)

    def set_location(self, location):
        if location:
            self.address = funcs.shorten_addr(location=location)
            self.latitude = location.latitude
            self.longitude = location.longitude
            self.sin_rad_lat = math.sin(math.pi * location.latitude / 180)
            self.cos_rad_lat = math.cos(math.pi * location.latitude / 180)
            self.rad_lng = math.pi * location.longitude / 180

        return location
