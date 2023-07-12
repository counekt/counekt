// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./administrable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    /// @notice Struct representing info of a Referendum.
    /// @param issuer The issuer of the Referendum.
    /// @param proposalFunctionNames Names of functions to be called during implementation.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.
    struct ReferendumInfo {
        address issuer;
        string[] proposalFunctionNames;
        bytes[] proposalArgumentData;
    }

    /// @notice Mapping pointing to dynamic info of a Referendum given a unique Referendum instance.
    mapping(uint256 => ReferendumInfo) public infoByReferendum;

    /// @notice Mapping pointing to amount of favor votes on given Referendum.
    mapping(uint256 => uint256) favorAmountByReferendum;

    /// @notice Mapping pointing to amount of total votes on given Referendum.
    mapping(uint256 => uint256) totalAmountByReferendum;

    /// @notice Mapping pointing to amount proposals implemented of a given Referendum.
    mapping(uint256 => uint256) amountImplementedByReferendum;

    /// @notice Mapping pointing to a boolean stating if the holder of a given Shard has voted on the given Referendum.
    mapping(uint256 => mapping(bytes32 => bool)) hasVotedOnReferendum;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is pending.
    mapping(uint256 => bool) pendingReferendums;

    /// @notice Mapping pointing to a boolean stating if a given Referendum is to be implemented.
    mapping(uint256 => bool) passedReferendums;


    /// @notice Event that triggers when a Referendum is issued.
    /// @param referendum The now pending Referendum that was issued.
    event ReferendumIssued(
        uint256 referendum
        );

    /// @notice Event that triggers when a Referendum is closed.
    /// @param referendum The passed Referendum that was closed.
    event ReferendumClosed(
        uint256 referendum
        );

    /// @notice Event that triggers when a whole Referendum has been implemented.
    /// @param referendum The passed Referendum that was implemented.
    event ReferendumImplemented(
        uint256 referendum
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

    /// @notice Modifier that makes sure a given Referendum is pending.
    /// @param referendum The Referendum to be checked for.
    modifier onlyPendingReferendum(uint256 referendum) {
        require(referendumIsPending(referendum), "RNP");
        _;
    }

    constructor(uint256 amount) Administrable(amount) {
        _setPermit("iV",msg.sender,PermitState.administrator);
        _setPermit("iP",msg.sender,PermitState.administrator);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param shard The Shard to vote with.
    /// @param referendum The referendum to be voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    function vote(bytes32 shard, uint256 referendum, bool favor) external onlyHolder(shard) onlyPendingReferendum(referendum) onlyIfActive {
        require(!hasVoted(referendum, msg.sender));
        require(shardExisted(shard,referendum), "SNV");
        hasVotedOnReferendum[referendum][shard] = true;
        if (favor) {
            favorAmountByReferendum[referendum] += infoByShard[shard].amount;
        }
        totalAmountByReferendum[referendum] += infoByShard[shard].amount;
        
        emit VoteCast(referendum, favor, msg.sender);
        bool passed = getReferendumResult(referendum);
        if (passed || totalAmountByReferendum[referendum] == totalShardAmountByClock[referendum] ) {

            pendingReferendums[referendum] = false;
            if (passed) { // if it got voted through
                passedReferendums[referendum] = true;
            }
            emit ReferendumClosed(referendum);
        }
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposalFunctionNames The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.
    function issueVote(string[] memory proposalFunctionNames, bytes[] memory proposalArgumentData) external onlyWithPermit("iV") {
        _issueVote(proposalFunctionNames,proposalArgumentData);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function implementProposal(uint256 referendum, uint256 proposalIndex) external onlyWithPermit("iP") {
        _implementProposal(referendum,proposalIndex);
    }

    /// @notice Returns a boolean stating if a given Shard Holder has voted on a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param account The address of the potential Shard Holder voter to be checked for.
    function hasVoted(uint256 referendum, address account) public view returns(bool) {
        return hasVotedOnReferendum[referendum][shardByOwner[account]];
    }

    /// @notice Returns a boolean stating if a given Referendum has been voted through (>=50% FAVOR) or not.
    /// @param referendum The Referendum to be checked for.
    function getReferendumResult(uint256 referendum) public view returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if ((favorAmountByReferendum[referendum] / totalShardAmountByClock[referendum]) * 2 > 1) {
            return true;
        }
        return false;
    }
    
    /// @notice Returns a boolean stating if a given Referendum is pending or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPending(uint256 referendum) public view returns(bool) {
        return pendingReferendums[referendum]; 
    }

    /// @notice Returns a boolean stating if a given Referendum is passed or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsPassed(uint256 referendum) public view returns(bool) {
        return passedReferendums[referendum]; 
    }

    /// @notice Returns a boolean stating if a given Referendum is implemented or not.
    /// @param referendum The Referendum to be checked for.
    function referendumIsImplemented(uint256 referendum) public view returns(bool) {
        return amountImplementedByReferendum[referendum] == infoByReferendum[referendum].proposalFunctionNames.length; 
    }

    /// @notice Returns a boolean stating if a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    function proposalExists(uint256 referendum, uint256 proposalIndex) public view returns(bool) {
        return infoByReferendum[referendum].proposalFunctionNames.length > proposalIndex;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposalFunctionNames The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.
    function _issueVote(string[] memory proposalFunctionNames, bytes[] memory proposalArgumentData) internal onlyIfActive incrementClock {
        uint256 transferClock = clock;
        require(proposalFunctionNames.length == proposalArgumentData.length, "PCW");
        pendingReferendums[transferClock] = true;
        infoByReferendum[transferClock] = ReferendumInfo({
            issuer: msg.sender,
            proposalFunctionNames: proposalFunctionNames,
            proposalArgumentData: proposalArgumentData
            });
        emit ReferendumIssued(transferClock);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function _implementProposal(uint256 referendum, uint256 proposalIndex) internal onlyIfActive {
        require(proposalExists(referendum,proposalIndex),"PDE");
        require(amountImplementedByReferendum[referendum] == proposalIndex, "WPO");
        amountImplementedByReferendum[referendum] += 1;
        string memory proposalFunctionName = infoByReferendum[referendum].proposalFunctionNames[proposalIndex];
        bytes memory proposalArgumentData = infoByReferendum[referendum].proposalArgumentData[proposalIndex];
        bytes32 functionNameHash = keccak256(bytes(proposalFunctionName));
                    if (functionNameHash == keccak256(bytes("iV"))) {
                        (string[] memory proposalFunctionNames, bytes[] memory _proposalArgumentData) = abi.decode(proposalArgumentData, (string[], bytes[]));
                        _issueVote(proposalFunctionNames, _proposalArgumentData);
                    }
                    if (functionNameHash == keccak256(bytes("sP"))) {
                        (string memory permitName, PermitState newState, address account) = abi.decode(proposalArgumentData, (string, PermitState,address));
                        _setPermit(permitName,account,newState);
                    }
                    if (functionNameHash == keccak256(bytes("sB"))) {
                        (string memory permitName, PermitState newState) = abi.decode(proposalArgumentData, (string, PermitState));
                        _setBasePermit(permitName,newState);
                    }
                    if (functionNameHash == keccak256(bytes("tT"))) {
                        (string memory fromBankName, address tokenAddress, uint256 value, address to) = abi.decode(proposalArgumentData, (string, address, uint256,address));
                        _transferTokenFromBank(fromBankName,tokenAddress,value,to);
                    }
                    if (functionNameHash == keccak256(bytes("mT"))) {
                        (string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) = abi.decode(proposalArgumentData, (string, string, address, uint256));
                        _moveToken(fromBankName,toBankName,tokenAddress,value);
                    }
                    if (functionNameHash == keccak256(bytes("iD"))) {
                        (string memory bankName, address tokenAddress, uint256 value) = abi.decode(proposalArgumentData, (string,address,uint256));
                        _issueDividend(bankName,tokenAddress,value);
                    }
                    if (functionNameHash == keccak256(bytes("iS"))) {
                        (uint256 amount, address tokenAddress, uint256 price, address to) = abi.decode(proposalArgumentData, (uint256,address,uint256,address));
                        _issueShards(amount,tokenAddress,price,to);
                    }
                    if (functionNameHash == keccak256(bytes("dD"))) {
                        (uint256 dividend) = abi.decode(proposalArgumentData, (uint256));
                        _dissolveDividend(dividend);
                    }
                    if (functionNameHash == keccak256(bytes("cB"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        _createBank(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("dB"))) {
                        (string memory bankName) = abi.decode(proposalArgumentData, (string));
                        _deleteBank(bankName);
                    }
                    if (functionNameHash == keccak256(bytes("aBA"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        _addBankAdmin(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("rBA"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        _removeBankAdmin(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("rTA"))) {
                        (address tokenAddress) = abi.decode(proposalArgumentData, (address));
                        _registerTokenAddress(tokenAddress);
                    }
                    if (functionNameHash == keccak256(bytes("uTA"))) {
                        (address tokenAddress) = abi.decode(proposalArgumentData, (address));
                        _unregisterTokenAddress(tokenAddress);
                    }
                    if (functionNameHash == keccak256(bytes("l"))) {
                        _liquidize();
                    }
                    else {
                        revert("WF");
                    }
                    emit ActionTaken("iP",abi.encode(referendum,proposalIndex),msg.sender);

        if (amountImplementedByReferendum[referendum] == infoByReferendum[referendum].proposalFunctionNames.length) {
            emit ReferendumImplemented(referendum);
        }
    }
}