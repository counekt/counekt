from app import db, hybrid_method, hybrid_property, func
import math

# This class acts as a blueprint for the below tables


class Address():
    id = db.Column(db.Integer, primary_key=True, unique=True)

    lat = db.Column(db.Float)
    lng = db.Column(db.Float)

    number = db.Column(db.String)

    street = db.Column(db.String)

    sin_r_lat = db.Column(db.Float)
    cos_r_lat = db.Column(db.Float)
    r_lng = db.Column(db.Float)

    def __init__(self, **kwargs):
        super(self.__class__, self).__init__(**kwargs)
        self.sin_r_lat = math.sin(math.pi * self.lat / 180)
        self.cos_r_lat = math.cos(math.pi * self.lat / 180)
        self.r_lng = math.pi * self.lng / 180

    @hybrid_property
    def address(self):
        return f"{self.number} {self.street}"

    @hybrid_method
    def IS_WITHIN(self, sin_r_lat, cos_r_lat, r_lng, r):
        return func.acos(self.cos_r_lat
                         * cos_r_lat
                         * func.cos(self.r_lng - r_lng)
                         + self.sin_r_lat
                         * sin_r_lat
                         ) * 6371 <= r

    def is_within(self, lat, lng, r):
        sin_r_lat = math.sin(math.pi * lat / 180)
        cos_r_lat = math.cos(math.pi * lat / 180)
        r_lng = math.pi * lng / 180
        return math.acos(self.cos_r_lat
                         * cos_r_lat
                         * math.cos(self.r_lng - r_lng)
                         + self.sin_r_lat
                         * sin_r_lat
                         ) * 6371 <= r

    @classmethod
    def get_within(cls, lat, lng, r):
        sin_r_lat = math.sin(math.pi * lat / 180)
        cos_r_lat = math.cos(math.pi * lat / 180)
        r_lng = math.pi * lng / 180
        return cls.query.filter(cls.IS_WITHIN(sin_r_lat=sin_r_lat, cos_r_lat=cos_r_lat, r_lng=r_lng, r=r))


"""
    Note:
    The addresses are split up in tables
    by states to keep up the perfomance
    when querying.
"""


class AL(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class AK(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class AZ(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class AR(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class CA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class CO(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class CT(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class DC(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class DE(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class FL(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class GA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class HI(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class ID(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class IL(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class IN(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class IA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class KS(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class KY(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class LA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class ME(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MD(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MI(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MN(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MS(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MO(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class MT(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NE(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NV(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NH(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NJ(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NM(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NY(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class NC(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class ND(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class OH(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class OK(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class OR(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class PA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class RI(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class SC(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class SD(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class TN(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class TX(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class UT(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class VT(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class VA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class WA(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class WV(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class WI(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)


class WY(db.Model, Address):
    def __init__(self, **kwargs):
        Address.__init__(self, **kwargs)
