from app import db
import app.models as models
from app.models.base import Base

class Referendum(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	clock = db.Column(db.Integer) # clock of issuance, used to identify

	def __repr__(self):
		return '<Referendum {}>'.format(self.clock)