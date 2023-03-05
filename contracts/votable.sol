pragma solidity ^0.8.4;

import "../administable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    /// @notice The latest and most recent Referendum to be issued.
    Referendum latestReferendum;

    /// @notice Mapping pointing to dynamic info of a Referendum given a unique Referendum instance.
    mapping(Referendum => DynamicReferendumInfo) dynamicReferendumInfo;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is pending.
    mapping(Referendum => bool) referendumsPending;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is to be implemented.
    mapping(Referendum => bool) referendumsToBeImplemented;

    /// @notice A struct representing a Proposal that can be implemented by executing its specific function call data.
    /// @param functionName The name of the function to be called as a result of the implementation of the Proposal.
    /// @param argumentData The parameters passed to the function call as part of the implementation of the Proposal.
    struct Proposal {
        string functionName;
        bytes argumentData;
    }

    /// @notice A struct representing a Referendum that has proposals tied to it.
    /// @param creationTime The block.timestamp at which the Referendum was created. Used for identification.
    /// @param proposals An array of proposals connected to the Referendum.
    struct Referendum {
        uint256 creationTime;
        Proposal[] proposals;
    }

    /// @notice A struct representing the dynamic (non-constant) info of a Referendum struct.
    /// @param forFraction The fraction of Shard-holders who voting FOR the proposals.
    /// @param againstFraction The fraction of Shard-holders who voted AGAINST the proposals.
    /// @param hasVoted Mapping pointing to a boolean stating if the holder of a given Shard has voted on the Referendum.
    /// @param amountImplemented Amount of proposals implemented.
    struct DynamicReferendumInfo {
        Fraction forFraction;
        Fraction againstFraction;
        mapping(Shard => bool) hasVoted;
        uint256 amountImplemented;
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

    /// @notice Modifier that makes sure msg.sender has NOT voted on a specific referendum
    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    /// @notice Modifier that makes sure a given Referendum exists
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
    /// @param for The boolean value signalling a FOR or AGAINST vote.
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
        return referendumsPending[referendum] == true; 
    }

    function referendumTBIExists(Referendum referendum) returns(bool) {
        return referendumsToBeImplemented[referendum] == true; 
    }

    function proposalExists(Referendum referendum, uint256 proposalIndex) returns(bool) {
        return referendum.proposals.length > proposalIndex;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    function _issueVote(Proposal[] proposals, address by) internal onlyIfActive {
        Referendum referendum = new Referendum();
        referendum.creationTime = block.timestamp;
        referendum.proposals = proposals;
        pendingReferendums[referendum] = true;
        emit ReferendumIssued(referendum, by);
    }

    function _closeReferendum(Referendum referendum) internal onlyExistingReferendum(referendum) onlyIfActive {
        bool memory result = getReferendumResult(referendum);
        // remove the now closed Referendum from 'pendingReferendums'
        pendingReferendums[referendum] = false;
        if (result) { // if it got voted through
            referendumsToBeImplemented[referendum] = true;
        }
        emit ReferendumClosed(referendum, result);
    }

    function _implementProposal(Referendum referendum, uint256 proposalIndex) internal onlyIfActive onlyExistingReferendumTBI(referendum) onlyExistingProposal(referendum,proposal) {
        require(dynamicReferendumInfo[referendum].proposalsImplemented == proposalIndex, "Proposals must be executed in the correct order.");
        dynamicReferendumInfo[referendum].amountImplemented += 1;
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
        if (referendum.amountImplemented == referendum.proposals.length) {
            // remove fully implemented referendum from referendumsToBeImplemented
          _unregisterReferendumTBI(referendum);
        }
    }

    function _unregisterReferendumTBI(Referendum referendum) onlyExistingReferendumTBI(referendum) {
        referendumsToBeImplemented[referendum] = false;
    }

}