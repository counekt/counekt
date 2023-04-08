import pytest
from brownie import Shardable, Idea, Administrable, MockToken, accounts
import web3
import logging

LOGGER = logging.getLogger(__name__)

NULL_ADDRESS = "0x0000000000000000000000000000000000000000"

@pytest.fixture
def shardable():
	shardable = accounts[0].deploy(Shardable)
	return shardable

@pytest.fixture
def idea():
	idea = accounts[0].deploy(Idea)
	return idea

@pytest.fixture
def administrable():
	administrable = accounts[0].deploy(Administrable)
	return administrable

@pytest.fixture
def token():
	token = accounts[0].deploy(MockToken)
	token.mint(accounts[0],5000)
	token.mint(accounts[1],5000)
	return token

def test_shardTrade(shardable):
	shard = shardable.shardByOwner(accounts[0])
	assert shardable.isValidShard(shard) == True
	LOGGER.info(shard);
	tx = shardable.putForSale(shard,1,2,NULL_ADDRESS,500,{"from":accounts[0]})
	tx.wait(1)
	assert not shardable.isShardHolder(accounts[1])
	tx = shardable.purchase(shard,{"from":accounts[1], "value":shardable.infoByShard(shard)[-1]})
	tx.wait(1)
	assert shardable.isShardHolder(accounts[1])

def test_ethTrade(administrable):
	# Receipt
	assert administrable.liquid(NULL_ADDRESS)[0] == 0
	tx = accounts[1].transfer(administrable,"10 ether")
	tx.wait(1)
	assert administrable.liquid(NULL_ADDRESS)[0] != 0
	# Transfer 
	tx = administrable.transferTokenFromBank("main",NULL_ADDRESS,"10 ether",accounts[1], {"from":accounts[0]})
	tx.wait(1)
	assert administrable.liquid(NULL_ADDRESS)[0] == 0


def test_tokenTrade(administrable, token):
	# Receipt
	assert administrable.liquid(token.address)[0] == 0
	tx = administrable.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(administrable,1000, {"from":accounts[1]})
	tx.wait(1)
	tx = administrable.receiveToken(token.address,1000, {"from":accounts[1]})
	tx.wait(1)
	assert administrable.liquid(token.address)[0] != 0
	# Transfer
	tx = administrable.transferTokenFromBank("main",token.address,1000,accounts[1], {"from":accounts[0]})
	tx.wait(1)
	assert administrable.liquid(token.address)[0] == 0

def test_bankDynamics(administrable):
	# Fund the Idea
	tx = accounts[1].transfer(administrable,"10 ether")
	tx.wait(1)
	# Create additional Bank
	tx = administrable.createBank("marketingExpenses",accounts[0],{"from":accounts[0]})
	tx.wait(1)
	# Move 5 ether to that bank
	tx = administrable.moveToken("main","marketingExpenses",NULL_ADDRESS,"5 ether",{"from":accounts[0]})
	tx.wait(1)
	assert administrable.getBankBalance("main",NULL_ADDRESS) == administrable.getBankBalance("marketingExpenses",NULL_ADDRESS)
	# Make it possible for non shard holders to interfere
	tx = administrable.setNonShardHolderState(True,{"from":accounts[0]})
	tx.wait(1)
	# Set manage Bank permit of account 1 to authorized
	tx = administrable.setPermit("mB",accounts[1],1,{"from":accounts[0]})
	tx.wait(1)
	hasPermit = administrable.hasPermit("mB",accounts[1])
	assert hasPermit
	# Add account 1 to the new Bank as bank admin
	tx = administrable.addBankAdmin("marketingExpenses",accounts[1],{"from":accounts[0]})
	tx.wait(1)
	# Make account 1 transfer all the funds of that Bank to account 2
	tx = administrable.transferTokenFromBank("marketingExpenses",NULL_ADDRESS,"5 ether",accounts[2],{"from":accounts[1]})
	tx.wait(1)
	assert administrable.getBankBalance("marketingExpenses",NULL_ADDRESS) == 0

