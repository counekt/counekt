from app import db
import app.funcs as funcs
from sqlalchemy import func, inspect
import math
from sqlalchemy.ext.hybrid import hybrid_method


class Location(db.Model, Base):
    location_address = db.Column(db.String)
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)
    sin_rad_lat = db.Column(db.Float)
    cos_rad_lat = db.Column(db.Float)
    rad_lng = db.Column(db.Float)
    show_location = db.Column(db.Boolean, default=False)
    is_visible = db.Column(db.Boolean, default=False)

    def set_location(self, location):
        if location:
            self.location_address = funcs.shorten_addr(location=location)
            self.latitude = location.latitude
            self.longitude = location.longitude
            self.sin_rad_lat = math.sin(math.pi * location.latitude / 180)
            self.cos_rad_lat = math.cos(math.pi * location.latitude / 180)
            self.rad_lng = math.pi * location.longitude / 180

        return location

    @classmethod
    def get_explore_query(cls, latitude, longitude, radius):
        query = cls.query.filter(cls.is_nearby(latitude=float(latitude), longitude=float(longitude), radius=float(radius)))
        query = query.filter(cls.show_location == True, cls.is_visible == True)
        return query

    @ hybrid_method
    def is_nearby(self, latitude, longitude, radius):
        sin_rad_lat = math.sin(math.pi * latitude / 180)
        cos_rad_lat = math.cos(math.pi * latitude / 180)
        rad_lng = math.pi * longitude / 180
        return func.acos(self.cos_rad_lat
                         * cos_rad_lat
                         * func.cos(self.rad_lng - rad_lng)
                         + self.sin_rad_lat
                         * sin_rad_lat
                         ) * 6371 <= radius
