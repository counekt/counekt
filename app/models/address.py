from app import w3
import app.models as models

class Address:

	@classmethod
	def get_entity(cls,address):
		return models.ERC360.query.filter_by(address=address).first() or models.Wallet.query.filter_by(address=address).first()
