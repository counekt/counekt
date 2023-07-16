from app import db
import app.models as models
from app.models.base import Base

class Permit(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	name = db.Column(db.String) # name of permit
	state = db.Column(db.Integer) # state of permit: 0 (none), 1 (bishop), 2 (king)
	holder_address = db.Column(db.String(42)) # ETH address

	def __repr__(self):
		return '<Permit {}>'.format(self.name)