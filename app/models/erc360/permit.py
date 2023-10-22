from app import db
import app.models as models
from app.models.base import Base
from eth_utils import keccak
from eth_abi import encode
from sqlalchemy.ext.hybrid import hybrid_property, hybrid_method


class Permit(db.Model, Base):

	id = db.Column(db.Integer, primary_key=True)
	erc360_id = db.Column(db.Integer, db.ForeignKey('erc360.id', ondelete='CASCADE'))

	bytes = db.Column(db.LargeBinary(length=32)) # byte name of permit

	parent_id = db.Column(db.Integer, db.ForeignKey('permit.id', ondelete='CASCADE'))
	_parent = db.relationship("Permit",backref="children",remote_side=[id], cascade="all, delete")
	
	@hybrid_property
	def parent(self):
		return self._parent or self 

	@parent.setter
	def parent(self,new_parent):
		self._parent = new_parent if new_parent != self else None

	@property
	def title(self):
		return {PERMITS[0]:"Master Permit",
		PERMITS[1]: "Mint Permit",
		PERMITS[2]:"Vote Permit",
		PERMITS[3]:"Dividend Permit",
		PERMITS[4]:"Resolution Permit"
		}.get(self.bytes,"Permit")

	@classmethod
	def create_initial_permits(cls,erc360,creator):
		master_permit = Permit(bytes=PERMITS[0])
		master_permit.parent = master_permit
		master_permit.wallets.append(creator)
		erc360.permits.append(master_permit)
		for p_bytes in PERMITS[1:]:
			permit = Permit(bytes=p_bytes)
			permit.parent = master_permit
			erc360.permits.append(permit)
		master_bank = models.Bank(name="main")
		master_bank.permit = master_permit
		erc360.banks.append(master_bank)

	@hybrid_method
	def is_self_inclusive_descendant_of(self, ancestor):
		return True if self.id == ancestor.id \
		else self.id == ancestor.id if self.bytes == PERMITS[0] \
		else self.parent.is_self_inclusive_descendant_of(ancestor)


	def __repr__(self):
		return '<Permit {}>'.format(self.bytes.hex())

def keccak_256(string: str):	
	return keccak(encode(['string'],[string]))

PERMITS = [bytes(32),keccak_256("MINT"),keccak_256("ISSUE_VOTE"),keccak_256("ISSUE_DIVIDEND"),keccak_256("IMPLEMENT_RESOLUTION")]
