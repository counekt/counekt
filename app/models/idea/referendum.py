from app import db
import app.models as models
from app.models.base import Base

class Referendum(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	entity_id = db.Column(db.Integer, db.ForeignKey('idea.id', ondelete='CASCADE'))
	clock = db.Column(db.Integer) # clock of issuance, used to identify
	status = db.Column(db.Integer) # status, #0: issued, #1 closed, #2 implemented
	
	viable_amount = db.Column(db.Integer) # total amount of possible eligible votes
	cast_amount = db.Column(db.Integer) # total amount of votes cast
	in_favor_amount = db.Column(db.Integer) # total amount of votes cast in favor

	votes = db.relationship(
        'Vote', lazy='dynamic',
        foreign_keys='Vote.referendum_id', passive_deletes=True)
	proposals = db.relationship(
        'Proposal', lazy='dynamic',
        foreign_keys='Proposal.referendum_id', passive_deletes=True)
	def __repr__(self):
		return '<Referendum {}>'.format(self.clock)

class Proposal(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	func = db.Column(db.String) # Name of func to be called during implementation.
	args = db.Column(db.LargeBinary) #The encoded args passed to func call during implementation.
	def __init__(self, **kwargs):
        super(Proposal, self).__init__(**kwargs)
        # do custom initialization here
        # decode the args

	def __repr__(self):
		return '<Proposal {}>'.format(self.func)

class Vote(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	shard_id = db.Column(db.Integer) 
	shard = db.relationship("Shard", foreign_keys=[shard_id]) # the shard used to claim dividend
	in_favor = db.Column(db.Boolean) # states if in favors or not

	def __repr__(self):
		return '<Vote {} {}>'.format(self.amount, self.in_favor)

