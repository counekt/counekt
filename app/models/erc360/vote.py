from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class Referendum(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
	event_id = db.Column(db.Integer) # event id, used for identification
	clock = db.Column(db.BigInteger) # clock
	timestamp = db.Column(db.BigInteger) # ETH Block timestamp of creation
	duration = db.Column(db.Integer) # duration
	implemented = db.Column(db.Boolean,default=0) # status, #0: issued, #1 closed, #2 implemented
	
	viable_amount = db.Column(db.Integer) # total amount of possible eligible votes
	cast_amount = db.Column(db.Integer, default=0) # total amount of votes cast
	in_favor_amount = db.Column(db.Integer,default=0) # total amount of votes cast in favor

	votes = db.relationship(
        'ReferendumVote', lazy='dynamic',
        foreign_keys='ReferendumVote.referendum_id', passive_deletes=True)
	proposals = db.relationship(
        'ReferendumProposal', lazy='dynamic',
        foreign_keys='ReferendumProposal.referendum_id', passive_deletes=True)

	@hybrid_property
	def proposal_amount(self):
		return self.proposals.count()

	@hybrid_property
	def amount_implemented(self):
		return self.proposals.filter_by(implemented=True).count()
	
	def __repr__(self):
		return '<Referendum {}>'.format(self.clock)

class ReferendumProposal(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	index = db.Column(db.Integer) # Index as part of Referendum proposals
	sig = db.Column(db.LargeBinary(4)) # Name of func to be called during implementation.
	args = db.Column(db.LargeBinary) # The encoded args passed to func call during implementation.
	def __repr__(self):
		return '<Proposal {}>'.format(self.func)

class ReferendumVote(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	erc360_token_id_id = db.Column(db.Integer, db.ForeignKey('erc360_token_id.id', ondelete='CASCADE')) 
	erc360_token_id = db.relationship("ERC360TokenId", foreign_keys=[erc360_token_id_id]) # the shard used to claim dividend
	in_favor = db.Column(db.Boolean) # states if in favor or not

	def __repr__(self):
		return '<Vote {} {}>'.format(self.amount, "FAVOR" if self.in_favor else "AGAINST")

