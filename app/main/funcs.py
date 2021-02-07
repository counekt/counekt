from app.funcs import *
import math


def join_parts(*parts):
    return '/'.join(p.strip('/') for p in parts)


def get_zoom_from_rad(r):
    if r == 0:
        return 13
    return round(min(max(2, 15 - math.log2(r)), 13))
