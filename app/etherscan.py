from flask import abort
import requests

class Etherscan:
	def __init__(self, api_key, server="main"):
		self.api_key = api_key
		self.server = server

	def get_transactions_of(self,address,startblock=0,endblock=99999999,sort="asc"):
		src = f"https://api{'-'+self.server if self.server != 'main' else ''}.etherscan.io/api?module=account&action=txlist&address={address}&startblock={startblock}&endblock={endblock}&sort=asc&apikey={self.api_key}"
		response = requests.get(src)
		return response.json()["result"] if int(response.status_code) == 200 else abort(response.status_code)