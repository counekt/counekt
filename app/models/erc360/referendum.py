from app import db
import app.models as models
from app.models.base import Base
from sqlalchemy.ext.hybrid import hybrid_method, hybrid_property

class Referendum(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))
	identifier = db.Column(db.Integer) # event identifier, used for identification
	clock = db.Column(db.BigInteger) # clock
	timestamp = db.Column(db.BigInteger) # ETH Block timestamp of creation
	duration = db.Column(db.Integer) # duration
	implemented = db.Column(db.Boolean,default=0) # status, #0: issued, #1 closed, #2 implemented
	
	viable_amount = db.Column(db.Integer) # total amount of possible eligible votes
	cast_amount = db.Column(db.Integer, default=0) # total amount of votes cast
	in_favor_amount = db.Column(db.Integer,default=0) # total amount of votes cast in favor

	votes = db.relationship(
        'Vote', lazy='dynamic',
        foreign_keys='Vote.referendum_id', passive_deletes=True)
	proposals = db.relationship(
        'Proposal', lazy='dynamic',
        foreign_keys='Proposal.referendum_id', passive_deletes=True)

	@classmethod
	def get_or_register(cls,erc360,identifier):
		referendum = cls.query.filter(cls.identifier==identifier).first()
		if not referendum:
		    referendum = cls()
		    erc360.referendums.append(referendum)
		return referendum

	@hybrid_property
	def proposal_amount(self):
		return self.proposals.count()

	@hybrid_property
	def amount_implemented(self):
		return self.proposals.filter_by(implemented=True).count()
	
	def __repr__(self):
		return '<Referendum {}>'.format(self.clock)

class Proposal(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	index = db.Column(db.Integer) # Index as part of Referendum proposals
	sig = db.Column(db.LargeBinary(4)) # Name of func to be called during implementation.
	args = db.Column(db.LargeBinary) # The encoded args passed to func call during implementation.
	
	@classmethod
	def get_or_register(cls,referendum,index):
		proposal = cls.query.filter(cls.referendum_id==referendum.id,cls.index==index).first()
		if not proposal	:
		    proposal = cls()
		    referendum.proposals.append(proposal)
		return proposal

	def __repr__(self):
		return '<Proposal {}>'.format(self.func)

class Vote(db.Model, Base):
	id = db.Column(db.Integer, primary_key=True)
	referendum_id = db.Column(db.Integer, db.ForeignKey('referendum.id', ondelete='CASCADE'))
	erc360_shard_id = db.Column(db.Integer, db.ForeignKey('erc360_shard.id', ondelete='CASCADE')) 
	erc360_shard = db.relationship("ERC360Shard", foreign_keys=[erc360_shard_id]) # the shard used to claim dividend
	in_favor = db.Column(db.Boolean) # states if in favor or not

	def __repr__(self):
		return '<Vote {} {}>'.format(self.amount, "FAVOR" if self.in_favor else "AGAINST")

