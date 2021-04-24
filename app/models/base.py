from app import db

class Base:

    @property
    def exists_in_db(self):
        return bool(db.session.query(row.__class__).filter(row.__class__.id == row.id).first())
