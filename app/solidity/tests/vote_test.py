from main import *

def test_vote(votableWithTwoHolders):
	idea = votableWithTwoHolders
	assert not idea.referendumIsPending(0)
	idea.issueVote(["cB"],[eth_abi.encode(["string", "address"],["newBank",accounts[0].address])],True,{"from":accounts[0]})
	assert idea.referendumIsPending(0)
	idea.vote(idea.shardByOwner(accounts[0]),0,True,{"from":accounts[0]})
	idea.vote(idea.shardByOwner(accounts[1]),0,True,{"from":accounts[1]})
	assert votableWithTwoHolders.referendumIsPassed(0)

	idea.implementProposal(0,0, {"from":accounts[0]})
	assert idea.referendumIsImplemented(0)
	assert idea.bankExists("newBank") and not idea.bankExists("wedwedwon")
