from app import db

class Base:

    @property
    def exists_in_db(self):
        return bool(db.session.query(self.__class__).filter(self.__class__.id == self.id).first())
