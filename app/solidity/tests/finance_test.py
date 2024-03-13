from main import *

def test_bankDynamics(votable):
	# Fund the Idea
	tx = accounts[1].transfer(votable,"10 ether")
	tx.wait(1)
	# Create additional Bank
	tx = votable.createBank("marketingExpenses",accounts[0],{"from":accounts[0]})
	tx.wait(1)
	# Move 5 ether to that bank
	tx = votable.moveToken("main","marketingExpenses",NULL_ADDRESS,"5 ether",{"from":accounts[0]})
	tx.wait(1)
	assert votable.getBankBalance("main",NULL_ADDRESS) == votable.getBankBalance("marketingExpenses",NULL_ADDRESS)
	# Make it possible for non shard holders to interfere
	tx = votable.setNonShardHolderState(True,{"from":accounts[0]})
	tx.wait(1)
	# Set manage Bank permit of account 1 to authorized
	tx = votable.setPermit("mB",accounts[1],1,{"from":accounts[0]})
	tx.wait(1)
	hasPermit = votable.hasPermit("mB",accounts[1])
	assert hasPermit
	# Add account 1 to the new Bank as bank admin
	tx = votable.addBankAdmin("marketingExpenses",accounts[1],{"from":accounts[0]})
	tx.wait(1)
	# Make account 1 transfer all the funds of that Bank to account 2
	tx = votable.transferTokenFromBank("marketingExpenses",NULL_ADDRESS,"5 ether",accounts[2],{"from":accounts[1]})
	tx.wait(1)
	assert votable.getBankBalance("marketingExpenses",NULL_ADDRESS) == 0

def test_dividend(votableWithTwoHolders, token):
	idea = votableWithTwoHolders
	# Send idea 10 ether
	tx = accounts[0].transfer(idea,"10 ether")
	tx.wait(1)
	# Send some mock tokens too
	tx = idea.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(idea,1000, {"from":accounts[0]})
	tx.wait(1)
	tx = idea.receiveToken(token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	# Issue the dividends	
	tx = idea.issueDividend("main",NULL_ADDRESS,"10 ether", {"from":accounts[0]})
	tx.wait(1)
	tx = idea.issueDividend("main",token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	assert idea.getDividendValue(0) == idea.getDividendResidual(0)
	assert idea.getDividendValue(1) == idea.getDividendResidual(1)
	tx = idea.claimDividend(idea.shardByOwner(accounts[1]),0,{"from":accounts[1]})
	tx.wait(1)
	tx = idea.claimDividend(idea.shardByOwner(accounts[0]),0,{"from":accounts[0]})
	tx.wait(1)
	tx = idea.claimDividend(idea.shardByOwner(accounts[1]),1,{"from":accounts[1]})
	tx.wait(1)
	tx = idea.claimDividend(idea.shardByOwner(accounts[0]),1,{"from":accounts[0]})
	tx.wait(1)
	assert idea.getDividendResidual(0) != idea.getDividendValue(0)
	assert idea.getDividendResidual(1) != idea.getDividendValue(1)
	# Dissolve dividend
	tx = idea.dissolveDividend(0,{"from":accounts[0]})
	tx.wait(1)
	tx = idea.dissolveDividend(1,{"from":accounts[0]})
	tx.wait(1)
	assert not idea.dividendExists(0) and not idea.dividendExists(1)


def test_liquidization(votableWithTwoHolders, token):
	idea = votableWithTwoHolders
	# Send idea 10 ether
	tx = accounts[0].transfer(idea,"10 ether")
	tx.wait(1)
	# Send some mock tokens too
	tx = idea.registerTokenAddress(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = token.approve(idea,1000, {"from":accounts[0]})
	tx.wait(1)
	tx = idea.receiveToken(token.address,1000, {"from":accounts[0]})
	tx.wait(1)
	# Liquidization
	tx = idea.liquidize({"from":accounts[0]})
	tx.wait(1)
	assert idea.getLiquidResidual(NULL_ADDRESS) == idea.liquid(NULL_ADDRESS)
	assert idea.getLiquidResidual(token.address) == idea.liquid(token.address)
	# Claim the liquids
	tx = idea.claimLiquid(NULL_ADDRESS,{"from":accounts[0]})
	tx.wait(1)
	tx = idea.claimLiquid(NULL_ADDRESS,{"from":accounts[1]})
	tx.wait(1)
	tx = idea.claimLiquid(token.address,{"from":accounts[0]})
	tx.wait(1)
	tx = idea.claimLiquid(token.address,{"from":accounts[1]})
	tx.wait(1)
	assert idea.getLiquidResidual(token.address) != idea.liquid(token.address)
	assert idea.getLiquidResidual(NULL_ADDRESS) != idea.liquid(NULL_ADDRESS)
