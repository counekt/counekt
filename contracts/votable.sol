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
    mapping(Referendum => bool) pendingReferendums;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is to be implemented.
    mapping(Referendum => bool) passedReferendums;

    /// @notice A struct representing a Proposal that can be implemented by executing its specific function call data.
    /// @param functionName The name of the function to be called as a result of the implementation of the Proposal.
    /// @param argumentData The parameters passed to the function call as part of the implementation of the Proposal.
    struct Proposal {
        string functionName;
        bytes argumentData;
    }

    /// @notice A struct representing a Referendum that has proposals tied to it.
    /// @param creationTime The block.timestamp at which the Referendum was created. Used for identification.
    /// @param allowDivision A boolean stating if the Referendum is allowed to be implemented gradually.
    /// @param proposals An array of proposals connected to the Referendum.
    struct Referendum {
        uint256 creationTime;
        bool allowDivision;
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

    /// @notice Event that triggers when a Referendum is issued.
    event ReferendumIssued(
        Referendum referendum,
        address by
        );

    /// @notice Event that triggers when a Referendum is closed.
    event ReferendumClosed(
        Referendum referendum,
        bool result
        );

    /// @notice Event that triggers when a whole Referendum has been implemented.
    event ReferendumImplemented(
        Referendum referendum
        );
    
    /// @notice Event that triggers when a Proposal is implemented.
    event ProposalImplemented(
      Proposal proposal,
      Referendum referendum
      );

    /// @notice Event that triggers when a vote is cast on a Referendum.
    event VoteCast(
        Referendum referendum,
        Shard shard,
        bool for,
        address by
        );

    /// @notice Modifier that makes sure msg.sender has NOT voted on a specific referendum.
    /// @param referendum The Referendum to be checked for.
    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    /// @inheritdoc referendumIsPending
    /// @notice Modifier that makes sure a given Referendum is pending.
    modifier onlyPendingReferendum(Referendum referendum) {
        require(referendumIsPending(referendum), "Referendum is NOT pending!");
    }

    /// @inheritdoc referendumIsPassed
    /// @notice Modifier that makes sure a given Referendum is passed.
    modifier onlyPassedReferendum(Referendum referendum) {
        require(referendumIsPassed(referendum), "Referendum has NOT been passed!");
    }

    /// @inheritdoc proposalExists
    /// @notice Modifier that makes sure a given Proposal exists within a given Referendum.
    modifier onlyExistingProposal(Referendum referendum, uint256 proposalIndex) {
        require(proposalExists(referendum,proposalIndex), "Proposal does NOT exists!");
    }

    /// @inheritdoc _issueVote
    function issueVote(Proposal[] proposals, bool allowDivision) external onlyWithPermit("issueVote") {
        _issueVote(proposals, allowDivision);
    }

    /// @inheritdoc _implementReferendum
    function implementReferendum(Referendum referendum) external onlyWithPermit("implementProposal") {
        _implementReferendum(referendum);
    }

    /// @inheritdoc _implementProposal
    function implementProposal(Referendum referendum, Proposal proposal) external onlyWithPermit("implementProposal") {
        require(referendum.allowDivision, "This Referendum is not allowed to be gradually implemented. Consider using the 'implementReferendum' function instead.")
        _implementProposal(referendum, proposal);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param referendum The referendum to be voted on.
    /// @param for The boolean value signalling a FOR or AGAINST vote.
    function vote(Shard shard, Referendum referendum, bool for) external onlyHistoricShardHolder onlyPendingReferendum(referendum) hasNotVoted(referendum) onlyIfActive {
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(shardExisted(referendum.creationTime), "Shard is not applicable for this vote!");
        referendum.hasVoted[shard] = true;
        if (for) {
            referendum.forFraction = simplifyFraction(addFractions(referendum.forFraction,shard.fraction));
        }
        else {
            referendum.againstFraction = simplifyFraction(addFractions(referendum.againstFraction,shard.fraction));
        }
        emit VoteCast(referendum, shard, for, msg.sender);
    }

    /// @notice Returns a boolean stating if a given Shard Holder has voted on a given Referendum.
    /// @param shardHolder The address of the potential Shard Holder voter to be checked for.
    /// @param referendum The Referendum to be checked for.
    function hasVoted(address shardHolder, Referendum referendum) view returns(bool) {
        return referendum.hasVoted[shardByOwner[shardholder]];
    }

    /// @notice Returns a boolean stating if a given Referendum has been voted through (>=50% FOR) or not.
    /// @param referendum The Referendum to be checked for.
    function getReferendumResult(Referendum referendum) pure returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if (referendum.forFraction.numerator / referendum.forFraction.denominator > 0.5) {
            return true;
        }
        return false;
    }
    
    /// @notice Returns a boolean stating if a given Referendum is pending or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPending(Referendum referendum) returns(bool) {
        return pendingReferendums[referendum] == true; 
    }

    /// @notice Returns a boolean stating if a given Referendum is passed or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPassed(Referendum referendum) returns(bool) {
        return passedReferendums[referendum] == true; 
    }

    /// @notice Returns a boolean stating if a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    function proposalExists(Referendum referendum, uint256 proposalIndex) returns(bool) {
        return referendum.proposals.length > proposalIndex;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    function _issueVote(Proposal[] proposals, bool allowDivision, address by) internal onlyIfActive {
        Referendum referendum = new Referendum();
        referendum.creationTime = block.timestamp;
        referendum.allowDivision = allowDivision;
        referendum.proposals = proposals;
        pendingReferendums[referendum] = true;
        emit ReferendumIssued(referendum, by);
    }

    /// @notice Closes a given Referendum, leading to a pass or not.
    /// @param referendum The Referendum to be closed.
    function _closeReferendum(Referendum referendum) internal onlyPendingReferendum(referendum) onlyIfActive {
        bool memory result = getReferendumResult(referendum);
        // remove the now closed Referendum from 'pendingReferendums'
        pendingReferendums[referendum] = false;
        if (result) { // if it got voted through
            passedReferendums[referendum] = true;
        }
        emit ReferendumClosed(referendum, result);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function _implementProposal(Referendum referendum, uint256 proposalIndex) internal onlyIfActive onlyPassedReferendum(referendum) onlyExistingProposal(referendum,proposalIndex) {
        require(dynamicReferendumInfo[referendum].amountImplemented == proposalIndex, "Proposals must be executed in the correct order!");
        dynamicReferendumInfo[referendum].amountImplemented += 1;
        Proposal memory proposal = referendum.proposals[proposalIndex];
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
        emit ProposalImplemented(proposal, referendum);
        if (referendum.amountImplemented == referendum.proposals.length) {
            emit ReferendumImplemented(referendum);
        }

    }

    /// @notice Fully implements a given passed Referendum.
    /// @param referendum The passed Referendum to be fully implemented.
    function _implementReferendum(Referendum referendum) internal onlyIfActive onlyPassedReferendum(referendum) {
        require(referendum.amountImplemented < referendum.proposals.length, "Referendum ALREADY implemented!!!")
        for (uint256 pIndex=referendum.amountImplemented; pIndex<referendum.proposals.length; pIndex++) {
            _implementProposal(referendum,pIndex);
        }
    }
}