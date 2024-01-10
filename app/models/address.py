from app import w3
import app.models as models

class Address:

	@classmethod
	def get_entity(cls,address):
		return models.ERC360.query.filter_by(address=address).first() or models.Wallet.query.filter_by(address=address).first()

	@classmethod
	def get_or_register_entity(cls,address):
		entity = cls.get_entity()
		return entity if entity else models.Contract.get_or_register() if cls.is_contract(address) else models.Wallet.get_or_register()


	@classmethod
	def is_contract(self,address):
		return w3.eth.getCode(address) != "0x"

class Contract:
	pass
