import pytest
from brownie import Votable, MockToken, accounts
import eth_abi
import logging

# preparing

LOGGER = logging.getLogger(__name__)

NULL_ADDRESS = "0x0000000000000000000000000000000000000000"

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

