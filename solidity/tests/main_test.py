import pytest
from brownie import Shardable, Idea, Administrable, Votable, MockToken, accounts
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

def test_shardTrade(administrableWithTwoHolders):
	return administrableWithTwoHolders

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

def test_dividend(administrableWithTwoHolders, token):
	# Send administrable 10 ether
	tx = accounts[0].transfer(administrableWithTwoHolders,"10 ether")
	tx.wait(1)
	# Send some mock tokens too
	tx = administrableWithTwoHolders.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(administrableWithTwoHolders,1000, {"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.receiveToken(token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	# Issue the dividends	
	tx = administrableWithTwoHolders.issueDividend("main",NULL_ADDRESS,"10 ether", {"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.issueDividend("main",token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	assert administrableWithTwoHolders.getDividendValue(0) == administrableWithTwoHolders.getDividendResidual(0)
	assert administrableWithTwoHolders.getDividendValue(1) == administrableWithTwoHolders.getDividendResidual(1)
	tx = administrableWithTwoHolders.claimDividend(administrableWithTwoHolders.shardByOwner(accounts[1]),0,{"from":accounts[1]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimDividend(administrableWithTwoHolders.shardByOwner(accounts[0]),0,{"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimDividend(administrableWithTwoHolders.shardByOwner(accounts[1]),1,{"from":accounts[1]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimDividend(administrableWithTwoHolders.shardByOwner(accounts[0]),1,{"from":accounts[0]})
	tx.wait(1)
	assert administrableWithTwoHolders.getDividendResidual(0) != administrableWithTwoHolders.getDividendValue(0)
	assert administrableWithTwoHolders.getDividendResidual(1) != administrableWithTwoHolders.getDividendValue(1)
	# Dissolve dividend
	tx = administrableWithTwoHolders.dissolveDividend(0,{"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.dissolveDividend(1,{"from":accounts[0]})
	tx.wait(1)
	assert not administrableWithTwoHolders.dividendExists(0) and not administrableWithTwoHolders.dividendExists(1)


def test_liquidization(administrableWithTwoHolders, token):
	# Send administrable 10 ether
	tx = accounts[0].transfer(administrableWithTwoHolders,"10 ether")
	tx.wait(1)
	# Send some mock tokens too
	tx = administrableWithTwoHolders.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(administrableWithTwoHolders,1000, {"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.receiveToken(token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	# Liquidization
	tx = administrableWithTwoHolders.liquidize({"from":accounts[0]})
	tx.wait(1)
	assert administrableWithTwoHolders.getLiquidResidual(NULL_ADDRESS) == administrableWithTwoHolders.liquid(NULL_ADDRESS)
	assert administrableWithTwoHolders.getLiquidResidual(token.address) == administrableWithTwoHolders.liquid(token.address)
	# Claim the liquids
	tx = administrableWithTwoHolders.claimLiquid(NULL_ADDRESS,{"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimLiquid(NULL_ADDRESS,{"from":accounts[1]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimLiquid(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = administrableWithTwoHolders.claimLiquid(token.address,{"from":accounts[1]})
	tx.wait(1)
	assert administrableWithTwoHolders.getLiquidResidual(token.address) != administrableWithTwoHolders.liquid(token.address)
	assert administrableWithTwoHolders.getLiquidResidual(NULL_ADDRESS) != administrableWithTwoHolders.liquid(NULL_ADDRESS)

def test_vote(votableWithTwoHolders):
	assert not votableWithTwoHolders.referendumIsPending(0)
	votableWithTwoHolders.issueVote(["cB"],[eth_abi.encode(["string", "address"],["newBank",accounts[0].address])],True,{"from":accounts[0]})
	assert votableWithTwoHolders.referendumIsPending(0)
	votableWithTwoHolders.vote(votableWithTwoHolders.shardByOwner(accounts[0]),0,True,{"from":accounts[0]})
	votableWithTwoHolders.vote(votableWithTwoHolders.shardByOwner(accounts[1]),0,True,{"from":accounts[1]})
	assert votableWithTwoHolders.referendumIsPassed(0)

	votableWithTwoHolders.implementProposal(0,0, {"from":accounts[0]})
	assert votableWithTwoHolders.referendumIsImplemented(0)
	assert votableWithTwoHolders.bankExists("newBank") and not votableWithTwoHolders.bankExists("wedwedwon")
