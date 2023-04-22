from app import db
from app.models.base import Base


class Skill(db.Model, Base):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(20), index=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id', ondelete='CASCADE'))

    def __repr__(self):
        return "<Skill {}>".format(self.title)
