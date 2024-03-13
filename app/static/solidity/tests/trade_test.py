from main import *

def test_shardTrade(votableWithTwoHolders):
	return votableWithTwoHolders

def test_ethTrade(votable):
	idea = votable
	# Receipt
	assert idea.liquid(NULL_ADDRESS) == 0
	tx = accounts[1].transfer(idea,"10 ether")
	tx.wait(1)
	assert idea.liquid(NULL_ADDRESS) != 0
	# Transfer 
	tx = idea.transferTokenFromBank("main",NULL_ADDRESS,"10 ether",accounts[1], {"from":accounts[0]})
	tx.wait(1)
	assert idea.liquid(NULL_ADDRESS) == 0


def test_tokenTrade(votable, token):
	idea = votable
	# Receipt
	assert idea.liquid(token.address) == 0
	tx = idea.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(idea,1000, {"from":accounts[1]})
	tx.wait(1)
	tx = idea.receiveToken(token.address,1000, {"from":accounts[1]})
	tx.wait(1)
	assert idea.liquid(token.address) != 0
	# Transfer
	tx = idea.transferTokenFromBank("main",token.address,1000,accounts[1], {"from":accounts[0]})
	tx.wait(1)
	assert idea.liquid(token.address) == 0