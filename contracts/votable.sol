pragma solidity ^0.8.4;

import "../administable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @dev Need to figure out how to keep Shards consistent during trades for full voting percentage. Hint: mapping(Shard => Shard) shardSplitFrom;
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    // Referendums Not Yet Initialized
    Referendum[] referendumsNYI;
    mapping(Referendum => uint256) referendumNYIIndex; // starts from 1 and up, to differentiate betweeen empty values

	// Pending Referendums
    Referendum[] pendingReferendums;
    mapping(Referendum => uint256) pendingReferendumIndex; // starts from 1 and up, to differentiate betweeen empty values

    // Referendums To Be Implemented
    Referendum[] referendumsTBI;
    mapping(Referendum => uint256) referendumTBIIndex; // starts from 1 and up, to differentiate betweeen empty values

    struct Proposal {
        bytes4 functionSignifier;
        bytes argumentData;
    }

    struct Referendum {
        uint256 creationTime;
        Proposal[] proposals;
        mapping(Proposal => uint256) proposalIndex; // starts from 1 and up, to differentiate betweeen empty values
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
    /// @dev I f'cked it up. Now it's time based. Only Shards born before creation and potentially burned afterwards can vote.
    function vote(Shard shard, Referendum referendum, bool for) external onlyHistoricShardHolder onlyExistingReferendum(referendum) hasNotVoted(referendum) onlyIfActive {
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(shardExisted(referendum.creationTime), "Shard is not applicable for this vote!");
        referendum.hasVoted[shard] = true;
        if (for) {
            referendum.forFraction = simplifyFraction(addFractions(referendum.forFraction,shard.fraction));
        }
        else {
            referendum.againstFraction = simplifyFraction(addFractions(referendum.againstFraction,shard.fraction));
        }
        emit VoteCast(msg.sender, referendum, shard, for);
    }


    function hasVoted(address shardHolder, Referendum referendum) view returns(bool) {
        return referendum.hasVoted[shardByOwner[shardholder]];
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
        Referendum referendum = new Referendum();
        referendum.creationTime = block.timestamp;
        referendum.proposals = proposals;
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
                        require(issueVote.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        Proposal[] proposals = abi.decode(proposal.argumentData, (Proposal[]));
                        _issueVote(proposals, this.address);
                        break;
                    case "changePermit":
                        require(changePermit.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (address shardHolder, string permitName, bool newState) = abi.decode(proposal.argumentData, (address, string, bool));
                        _changePermit(shardholder,permitName,newState,this.address);
                        break;
                    case "transferToken":
                        require(transferToken.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (string fromBankName, address tokenAddress, uint256 value, address to) = abi.decode(proposal.argumentData, (string, address, uint256,address));
                        _transferTokenFromBank(fromBankName,tokenAddress,value,to,this.address);
                        break;
                    case "moveToken":
                        require(moveToken.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (string fromBankName, string toBankName, address tokenAddress, uint256 value) = abi.decode(proposal.argumentData, (string, string, address, uint256));
                        _moveToken(fromBankName,toBankName,tokenAddress,value,this.address);
                        break;
                    case "issueDividend":
                        require(issueDividend.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (string bankName, address tokenAddress, uint256 value) = abi.decode(proposal.argumentData, (string,address,uint256));
                        _issueDividend(bankName,tokenAddress,value,this.address);
                        break;
                    case "dissolveDividend":
                        require(dissolveDividend.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (Dividend dividend) = abi.decode(proposal.argumentData, (Dividend));
                        _dissolveDividend(dividend,this.address);
                        break;
                    case "createBank":
                        require(createBank.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (string bankName, bankAdministrator) = abi.decode(proposal.argumentData, (string, address));
                        _createBank(bankName,bankAdministrator,this.address);
                        break;
                    case "deleteBank":
                        require(deleteBank.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        (string bankName) = abi.decode(proposal.argumentData, (string));
                        _deleteBank(bankName, this.address);
                        break;
                    case "liquidize":
                        require(_liquidize.selector == abi.decode(proposal.argumentData,(bytes4)), "Arguments don't fit!");
                        _liquidize();
                        break;
        }
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