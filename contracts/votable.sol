pragma solidity ^0.8.4;

import "../administerable.sol";

/// @title A fractional DAO-like contract which decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a "democratically" administerable business entity.
/// @dev About to figure out how to do the structure of Proposals right - it can't just be about permits
/// @custom:beaware This is a commercial contract.
contract Votable is Administerable {

	constructor() public {
        super.constructor();
    }

	// Pending Referendums
    Referendum[] internal pendingReferendums;
    mapping(Referendum => uint256) pendingReferendumIndex; // starts from 1 and up, to differentiate betweeen empty values

    // Referendums To Be Implemented
    Referendum[] referendumsTBI;
    mapping(Referendum => uint256) referendumTBIIndex; // starts from 1 and up, to differentiate betweeen empty values

    struct Proposal {
        string functionName;
        Argument[] arguments;
    }

    enum ArgumentType {
    	_bool,
    	_uint256,
    	_string,
    	_proposal,
    	_dividend
    }

    struct Argument {
    	ArgumentType type;
    	bool _bool;
    	uint256 _uint256;
    	string _string;
    	address _address;
    	Proposal _proposal;
    	Dividend _dividend;
    }

    struct Referendum {
        Proposal[] proposals;
        mapping(Proposal => uint256) proposalIndex;
        Fraction forFraction;
        Fraction againstFraction;
        mapping(Shard => bool) hasVoted;
    }

    // triggers when a referendum is issued
    event ReferendumIssued(
        Referendum referendum,
        address by
        );

    // triggers when a referendum is closed
    event ReferendumClosed(
        Referendum referendum,
        bool result
        );
        
    event ProposalImplemented(
      Proposal proposal,
      Referendum referendum
      );

    // triggers when a vote is cast
    event VoteCast(
        address by,
        Referendum referendum,
        Shard shard,
        bool for
        );

    // modifier to make sure msg.sender has NOT voted on a specific referendum
    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    // modifier to make sure referendum exists
    modifier onlyExistingReferendum(Referendum referendum) {
        require(referendumExists(referendum), "Referendum does NOT exist!");
    }

    // modifier to make sure referendumTBI exists
    modifier onlyExistingReferendumTBI(Referendum referendum) {
        require(referendumTBIExists(referendum), "Referendum To Be Implemented does NOT exist!");
    }

    modifier onlyExistingProposal(Referendum referendum, Proposal proposal) {
        require(proposalExists(referendum,proposal), "Proposal does NOT exists!");
    }

     function issueVote(Proposal[] proposals) external onlyWithPermit("issueVote") {
        _issueVote(proposals);
    }

    function implementProposal(Referendum referendum, Proposal proposal) external onlyWithPermit("implementProposal") {
        _implementProposal(referendum, proposal);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param referendum The referendum to be voted on.
    /// @param for The boolean value signalling a for or against vote.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the right of the new shard to vote may unfairly perish, possibly making a referendum unsolvable.
    function vote(Referendum referendum, bool for) external onlyShardHolder hasNotVoted(referendum) onlyIfActive {
        Shard memory _shard = shardByOwner[msg.sender];
        if (for) {
            referendum.forFraction = simplifyFraction(addFractions(referendum.forFraction,_shard.fraction));
        }
        else {
            referendum.againstFraction = simplifyFraction(addFractions(referendum.againstFraction,_shard.fraction));
        }
        referendum.hasVoted[_shard] = true;
        emit VoteCast(msg.sender, referendum, _shard, for);
    }


    function hasVoted(address _shardHolder, Referendum referendum) view returns(bool) {
        return referendum.hasVoted[shardByOwner[_shardholder]];
    }

    function getReferendumResult(Referendum referendum) pure returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if (referendum.forFraction.numerator / referendum.forFraction.denominator > 0.5) {
            return true;
        }
        return false;
    }

    function referendumExists(Referendum referendum) returns(bool) {
        return referendumIndex[referendum] > 0; // bigger than 0 because stored indices start from 1
    }

    function referendumTBIExists(Referendum referendum) returns(bool) {
        return referendumsTBIIndex[referendum] > 0; // bigger than 0 because stored indices start from 1
    }

    function proposalExists(Referendum referendum, Proposal proposal) returns(bool) {
        return referendum.proposalIndex[proposal] > 0;
    }

    function _issueVote(Proposal[] proposals, address by) internal onlyIfActive {
        Referendum referendum = new Referendum(proposals);
        pendingReferendumIndex[referendum] = pendingReferendums.length+1; // +1 to distinguish between empty values
        pendingReferendums.push(referendum);
        emit ReferendumIssued(referendum, by);
    }

    function _closeReferendum(Referendum referendum) internal onlyExistingReferendum(referendum) onlyIfActive {
        bool memory result = getReferendumResult(referendum);
        // remove the now closed Referendum from 'pendingReferendums'
        pendingReferendums[pendingReferendumIndex[referendum]-1] = pendingReferendums[pendingReferendums.length-1]; // -1 because stored indices starts from 1
        pendingReferendumIndex[referendum] = 0; // a stored index value of 0 means empty
        pendingReferendums.pop()

        if (result) { // if it got voted through
            // the proposals are pushed to 'proposalsToBeImplemented'
            proposalsToBeImplemented.push(referendum.proposals);
        }
        emit ReferendumClosed(referendum, result);
    }

    function _implementProposal(Referendum referendum, Proposal proposal) internal onlyIfActive onlyExistingReferendumTBI(referendum) onlyExistingProposal(referendum,proposal) {
        _unregisterProposal(proposal);
        switch (proposal.functionName) {
                    case "issueVote":
                    	break // ...
                }
        this.call(bytes4(sha3(proposal.functionName+"("+proposal.arguments[0])));
        //this.call(bytes4(sha3(proposal.program)));
        if (referendum.proposals.length==0) {
            // remove fully implemented referendum from referendumsToBeImplemented
          _unregisterReferendumTBI(referendum);
        }
    }

    function _unregisterProposal(Referendum referendum, Proposal proposal) onlyExistingReferendumTBI(referendum) onlyExistingProposal(referendum, proposal) {
        referendum.proposals[referendum.proposalIndex[proposal]-1] = referendum.proposals[referendum.proposals.length-1];
        referendum.proposals.pop();
    }

    function _unregisterReferendumTBI(Referendum referendum) onlyExistingReferendumTBI(referendum) {
        referendumsTBI[referendumTBIIndex[referendum]-1] = referendumsTBI[referendumsTBI.length-1];
        referendumsTBI.pop();
    }



}