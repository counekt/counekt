import pytest
from brownie import Votable, MockToken, accounts
import eth_abi
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
def votable():
	votable = accounts[0].deploy(Votable)
	return votable

@pytest.fixture
def token():
	token = accounts[0].deploy(MockToken)
	token.mint(accounts[0],5000)
	token.mint(accounts[1],5000)
	return token

@pytest.fixture
def ideaWithTwoHolders(idea):
	shard = idea.shardByOwner(accounts[0])
	assert idea.isValidShard(shard) == True
	LOGGER.info(shard);
	tx = idea.putForSale(shard,1,2,NULL_ADDRESS,500,NULL_ADDRESS,{"from":accounts[0]})
	tx.wait(1)
	assert not idea.isShardHolder(accounts[1])
	value = idea.getShardSalePrice(shard)
	assert value > 0
	tx = idea.purchase(shard,{"from":accounts[1], "value":value})
	tx.wait(1)
	assert idea.isShardHolder(accounts[1])
	return idea

@pytest.fixture
def administrableWithTwoHolders(administrable):
	shard = administrable.shardByOwner(accounts[0])
	assert administrable.isValidShard(shard) == True
	LOGGER.info(shard);
	tx = administrable.putForSale(shard,1,2,NULL_ADDRESS,500,NULL_ADDRESS,{"from":accounts[0]})
	tx.wait(1)
	assert not administrable.isShardHolder(accounts[1])
	value = administrable.getShardSalePrice(shard)
	assert value > 0
	tx = administrable.purchase(shard,{"from":accounts[1], "value":value})
	tx.wait(1)
	assert administrable.isShardHolder(accounts[1])
	return administrable

@pytest.fixture
def votableWithTwoHolders(votable):
	shard = votable.shardByOwner(accounts[0])
	assert votable.isValidShard(shard) == True
	LOGGER.info(shard);
	tx = votable.putForSale(shard,1,2,NULL_ADDRESS,500,NULL_ADDRESS,{"from":accounts[0]})
	tx.wait(1)
	assert not votable.isShardHolder(accounts[1])
	value = votable.getShardSalePrice(shard)
	assert value > 0
	tx = votable.purchase(shard,{"from":accounts[1], "value":value})
	tx.wait(1)
	assert votable.isShardHolder(accounts[1])
	return votable

