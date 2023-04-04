import pytest
from brownie import Shardable, Idea, ERC20, accounts
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

def test_trade(shardable):
	shard = shardable.shardByOwner(accounts[0])
	assert shardable.isValidShard(shard) == True
	LOGGER.info(shard);
	tx = shardable.putForSale(shard,1,2,NULL_ADDRESS,500,{"from":accounts[0]})
	tx.wait(1)
	assert not shardable.isShardHolder(accounts[1])
	tx = shardable.purchase(shard,{"from":accounts[1], "value":shardable.infoByShard(shard)[-1]})
	tx.wait(1)
	assert shardable.isShardHolder(accounts[1])

def test_receive(idea):
	#idea.receive(5000, {"from":accounts[1]})