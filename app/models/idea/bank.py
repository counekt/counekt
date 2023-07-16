from app import db
import app.models as models
from app.models.base import Base

class Bank(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	name = db.Column(db.String) # name of bank

	def __repr__(self):
		return '<Bank {}>'.format(self.name)