pragma solidity ^0.8.4;

import "./administrable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    /// @notice A struct representing a Proposal that can be implemented by executing its specific function call data.
    /// @param functionName The name of the function to be called as a result of the implementation of the Proposal.
    /// @param argumentData The parameters passed to the function call as part of the implementation of the Proposal.
    struct Proposal {
        string functionName;
        bytes argumentData;
    }

    /// @notice A struct representing the information of a Referendum that has proposals tied to it.
    /// @param creationTime The block.timestamp at which the Referendum was created. Used for identification.
    /// @param allowDivision A boolean stating if the Referendum is allowed to be implemented gradually.
    /// @param proposals An array of proposals connected to the Referendum.
    /// @param forFraction The fraction of Shard-holders who voting FOR the proposals.
    /// @param againstFraction The fraction of Shard-holders who voted AGAINST the proposals.
    /// @param amountImplemented Amount of proposals implemented.
    struct ReferendumInfo {
        uint256 creationTime;
        bool allowDivision;
        Proposal[] proposals;
        Fraction favorFraction;
        Fraction againstFraction;
        uint256 amountImplemented;
    }

    /// @notice The latest and most recent Referendum to be issued.
    uint256 latestReferendum;

    /// @notice Mapping pointing to dynamic info of a Referendum given a unique Referendum instance.
    mapping(uint256 => ReferendumInfo) infoByReferendum;

    /// @notice Mapping pointing to a boolean stating if the holder of a given Shard has voted on the given Referendum.
    mapping(uint256 => mapping(bytes32 => bool)) hasVotedOnReferendum;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is pending.
    mapping(uint256 => bool) pendingReferendums;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is to be implemented.
    mapping(uint256 => bool) passedReferendums;


    /// @notice Event that triggers when a Referendum is issued.
    /// @param referendum The now pending Referendum that was issued.
    /// @param by The issuer of the Referendum.
    event ReferendumIssued(
        uint256 referendum,
        address by
        );

    /// @notice Event that triggers when a Referendum is closed.
    /// @param referendum The passed Referendum that was closed.
    /// @param result The result of the now closed Referendum.
    event ReferendumClosed(
        uint256 referendum,
        bool result
        );

    /// @notice Event that triggers when a whole Referendum has been implemented.
    /// @param referendum The passed Referendum that was implemented.
    event ReferendumImplemented(
        uint256 referendum
        );
    
    /// @notice Event that triggers when a Proposal is implemented.
    /// @param proposal The Proposal that was implemented.
    /// @param referendum The passed Referendum from which the Proposal was implemented.
    /// @param by The initiator of the Proposal implementation.
    event ProposalImplemented(
      Proposal proposal,
      uint256 referendum,
      address by
      );

    /// @notice Event that triggers when a vote is cast on a Referendum.
    /// @param referendum The referendum that was voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    /// @param by The voter.
    event VoteCast(
        uint256 referendum,
        bool favor,
        address by
        );

    /// @notice Modifier that makes sure msg.sender has NOT voted on a specific referendum.
    /// @param referendum The Referendum to be checked for.
    modifier hasNotVoted(uint256 referendum) {
        require(!hasVoted(msg.sender,referendum));
        _;

    }

    /// @notice Modifier that makes sure a given Referendum is pending.
    /// @param referendum The Referendum to be checked for.
    modifier onlyPendingReferendum(uint256 referendum) {
        require(referendumIsPending(referendum), "Referendum is NOT pending!");
        _;
    }

    /// @notice Modifier that makes sure a given Referendum is passed.
    /// @param referendum The Referendum to be checked for.
    modifier onlyPassedReferendum(uint256 referendum) {
        require(referendumIsPassed(referendum), "Referendum has NOT been passed!");
        _;
    }

    /// @notice Modifier that makes sure a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    modifier onlyExistingProposal(uint256 referendum, uint256 proposalIndex) {
        require(proposalExists(referendum,proposalIndex), "Proposal does NOT exists!");
        _;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposals The array of proposals to be tied to the Referendum.
    /// @param allowDivision A boolean stating if the proposals of the Referendum are allowed to be incrementally executed.
    function issueVote(Proposal[] memory proposals, bool allowDivision) external onlyWithPermit("issueVote") {
        _issueVote(proposals, allowDivision, msg.sender);
    }

    /// @notice Fully implements a given passed Referendum.
    /// @param referendum The passed Referendum to be fully implemented.
    function implementReferendum(uint256 referendum) external onlyWithPermit("implementProposal") {
        _implementReferendum(referendum, msg.sender);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function implementProposal(uint256 referendum, uint256 proposalIndex) external onlyWithPermit("implementProposal") {
        require(infoByReferendum[referendum].allowDivision, "This Referendum is not allowed to be gradually implemented. Consider using the 'implementReferendum' function instead.");
        _implementProposal(referendum, proposalIndex, msg.sender);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param shard The Shard to vote with.
    /// @param referendum The referendum to be voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    function vote(bytes32 shard, uint256 referendum, bool favor) external onlyHistoricShardHolder onlyPendingReferendum(referendum) hasNotVoted(referendum) onlyIfActive {
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(shardExisted(infoByReferendum[referendum].creationTime), "Shard is not applicable for this vote!");
        hasVotedOnReferendum[referendum][shard] = true;
        if (favor) {
            infoByReferendum[referendum].favorFraction = simplifyFraction(addFractions(infoByReferendum[referendum].favorFraction,infoByShard[shard].fraction));
        }
        else {
            infoByReferendum[referendum].againstFraction = simplifyFraction(addFractions(infoByReferendum[referendum].againstFraction,infoByShard[shard].fraction));
        }
        emit VoteCast(referendum, favor, msg.sender);
    }

    /// @notice Returns a boolean stating if a given permit is valid/exists or not.
    /// @param permitName The name of the permit to be checked for.
    function isValidPermit(string memory permitName) override public pure returns(bool) {
            bytes32 permitHash = keccak256(bytes(permitName));
            if (permitHash == keccak256(bytes("setRule"))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes(("issueVote")))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes("issueDividend"))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes("dissolveDividend"))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes("manageBank"))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes("implementProposal"))) {
                return true;
            }
            if (permitHash ==  keccak256(bytes("liquidizeEntity"))) {
                return true;
            }
            else {
                return false;
            }
    }

    /// @notice Returns a boolean stating if a given Shard Holder has voted on a given Referendum.
    /// @param _address The address of the potential Shard Holder voter to be checked for.
    /// @param referendum The Referendum to be checked for.
    function hasVoted(address _address, uint256 referendum) public view returns(bool) {
        return hasVotedOnReferendum[referendum][shardByOwner[_address]];
    }

    /// @notice Returns a boolean stating if a given Referendum has been voted through (>=50% FAVOR) or not.
    /// @param referendum The Referendum to be checked for.
    function getReferendumResult(uint256 referendum) public pure returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if ((infoByReferendum[referendum].favorFraction.numerator / infoByReferendum[referendum].favorFraction.denominator) > 0.5) {
            return true;
        }
        return false;
    }
    
    /// @notice Returns a boolean stating if a given Referendum is pending or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPending(uint256 referendum) public view returns(bool) {
        return pendingReferendums[referendum] == true; 
    }

    /// @notice Returns a boolean stating if a given Referendum is passed or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPassed(uint256 referendum) public view returns(bool) {
        return passedReferendums[referendum] == true; 
    }

    /// @notice Returns a boolean stating if a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    function proposalExists(uint256 referendum, uint256 proposalIndex) public view returns(bool) {
        return infoByReferendum[referendum].proposals.length > proposalIndex;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposals The array of proposals to be tied to the Referendum.
    /// @param allowDivision A boolean stating if the proposals of the Referendum are allowed to be incrementally executed.
    /// @param by The issuer of the Referendum.
    function _issueVote(Proposal[] memory proposals, bool allowDivision, address by) internal onlyIfActive {
        uint256 referendum = block.timestamp;
        ReferendumInfo memory referendumInfo = ReferendumInfo({
            creationTime:referendum,
            allowDivision:allowDivision,
            proposals:proposals,
            favorFraction: Fraction(0,1),
            againstFraction: Fraction(0,1),
            amountImplemented: 0
            });
        pendingReferendums[referendum] = true;
        infoByReferendum[referendum] = referendumInfo;
        emit ReferendumIssued(referendum, by);
    }

    /// @notice Closes a given Referendum, leading to a pass or not.
    /// @param referendum The Referendum to be closed.
    function _closeReferendum(uint256 referendum) internal onlyPendingReferendum(referendum) onlyIfActive {
        bool result = getReferendumResult(referendum);
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
    /// @param by The initiator of the Proposal implementation.
    function _implementProposal(uint256 referendum, uint256 proposalIndex, address by) internal onlyIfActive onlyPassedReferendum(referendum) onlyExistingProposal(referendum,proposalIndex) {
        require(infoByReferendum[referendum].amountImplemented == proposalIndex, "Proposals must be executed in the correct order!");
        infoByReferendum[referendum].amountImplemented += 1;
        Proposal memory proposal = infoByReferendum[referendum].proposals[proposalIndex];
        bytes32 functionNameHash = keccak256(bytes(proposal.functionName));
                    if (functionNameHash == keccak256(bytes("issueVote"))) {
                        (Proposal[] memory proposals, bool allowDivision) = abi.decode(proposal.argumentData, (Proposal[], bool));
                        _issueVote(proposals, allowDivision, address(this));
                    }
                    if (functionNameHash == keccak256(bytes("setPermit"))) {
                        (address _address, string memory permitName, PermitState newState) = abi.decode(proposal.argumentData, (address, string, PermitState));
                        _setPermit(_address,permitName,newState,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("setBasePermit"))) {
                        (string memory permitName, PermitState newState) = abi.decode(proposal.argumentData, (string, PermitState));
                        _setBasePermit(permitName,newState,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("setRule"))) {
                        (string memory ruleName, bool newState) = abi.decode(proposal.argumentData, (string, bool));
                        _setRule(ruleName,newState,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("transferToken"))) {
                        (string memory fromBankName, address tokenAddress, uint256 value, address to) = abi.decode(proposal.argumentData, (string, address, uint256,address));
                        _transferTokenFromBank(fromBankName,tokenAddress,value,to,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("moveToken"))) {
                        (string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) = abi.decode(proposal.argumentData, (string, string, address, uint256));
                        _moveToken(fromBankName,toBankName,tokenAddress,value,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("issueDividend"))) {
                        (string memory bankName, address tokenAddress, uint256 value) = abi.decode(proposal.argumentData, (string,address,uint256));
                        _issueDividend(bankName,tokenAddress,value,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("dissolveDividend"))) {
                        (uint256 dividend) = abi.decode(proposal.argumentData, (uint256));
                        _dissolveDividend(dividend,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("createBank"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposal.argumentData, (string, address));
                        _createBank(bankName,bankAdmin,address(this));
                    }
                    if (functionNameHash == keccak256(bytes("deleteBank"))) {
                        (string memory bankName) = abi.decode(proposal.argumentData, (string));
                        _deleteBank(bankName, address(this));
                    }
                    if (functionNameHash == keccak256(bytes("liquidize"))) {
                        _liquidize(address(this));
                    }
        emit ProposalImplemented(proposal, referendum, by);
        if (infoByReferendum[referendum].amountImplemented == infoByReferendum[referendum].proposals.length) {
            emit ReferendumImplemented(referendum);
        }

    }

    /// @notice Fully implements a given passed Referendum.
    /// @param referendum The passed Referendum to be fully implemented.
    /// @param by The initiator of the Referendum implementation.
    function _implementReferendum(uint256 referendum, address by) internal onlyIfActive onlyPassedReferendum(referendum) {
        require(infoByReferendum[referendum].amountImplemented < infoByReferendum[referendum].proposals.length, "Referendum ALREADY implemented!!!");
        for (uint256 pIndex=infoByReferendum[referendum].amountImplemented; pIndex<infoByReferendum[referendum].proposals.length; pIndex++) {
            _implementProposal(referendum,pIndex,by);
        }
    }
}