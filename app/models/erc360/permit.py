from app import db
import app.models as models
from app.models.base import Base


class Permit(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	bytes = db.Column(db.LargeBinary(length=32)) # byte name of permit

	parent_id = db.Column(db.Integer, db.ForeignKey('permit.id', ondelete='CASCADE'))
	parent = db.relationship("Permit",foreign_keys=[parent_id])
	
	def __repr__(self):
		return '<Permit {}>'.format(self.bytes)