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
    /// @param proposalFuncs Names of functions to be called during implementation.
    /// @param proposalArgs The encoded parameters passed to the function calls as part of the implementation of the proposals.
    struct ReferendumInfo {
        address issuer;
        string[] proposalFuncs;
        bytes[] proposalArgs;
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
    /// @param referendumClock The clock tied to the referendum that was voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    /// @param by The voter.
    event VoteCast(
        uint256 referendumClock,
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
        _setPermit("iR",msg.sender,PermitState.administrator);
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
    /// @param proposalFuncs The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgs The encoded parameters passed to the function calls as part of the implementation of the proposals.
    function issueReferendum(string[] memory proposalFuncs, bytes[] memory proposalArgs) external onlyWithPermit("iR") {
        _issueReferendum(proposalFuncs,proposalArgs);
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
        return amountImplementedByReferendum[referendum] == infoByReferendum[referendum].proposalFuncs.length; 
    }

    /// @notice Returns a boolean stating if a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    function proposalExists(uint256 referendum, uint256 proposalIndex) public view returns(bool) {
        return infoByReferendum[referendum].proposalFuncs.length > proposalIndex;
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposalFuncs The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgs The encoded parameters passed to the function calls as part of the implementation of the proposals.
    function _issueReferendum(string[] memory proposalFuncs, bytes[] memory proposalArgs) internal onlyIfActive incrementClock {
        require(proposalFuncs.length == proposalArgs.length, "PCW");
        pendingReferendums[clock] = true;
        infoByReferendum[clock] = ReferendumInfo({
            issuer: msg.sender,
            proposalFuncs: proposalFuncs,
            proposalArgs: proposalArgs
            });
        emit ActionTaken("iR",abi.encode(clock),msg.sender);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function _implementProposal(uint256 referendum, uint256 proposalIndex) internal onlyIfActive {
        require(proposalExists(referendum,proposalIndex),"PDE");
        require(amountImplementedByReferendum[referendum] == proposalIndex, "WPO");
        amountImplementedByReferendum[referendum] += 1;
        string memory proposalFunc = infoByReferendum[referendum].proposalFuncs[proposalIndex];
        bytes memory proposalArgs = infoByReferendum[referendum].proposalArgs[proposalIndex];
        bytes32 funcHash = keccak256(bytes(proposalFunc));
                    if (funcHash == keccak256(bytes("iR"))) {
                        (string[] memory proposalFuncs, bytes[] memory _proposalArgs) = abi.decode(proposalArgs, (string[], bytes[]));
                        _issueReferendum(proposalFuncs, _proposalArgs);
                    }
                    if (funcHash == keccak256(bytes("sP"))) {
                        (string memory permitName, PermitState newState, address account) = abi.decode(proposalArgs, (string, PermitState,address));
                        _setPermit(permitName,account,newState);
                    }
                    if (funcHash == keccak256(bytes("tT"))) {
                        (string memory fromBankName, address tokenAddress, uint256 value, address to) = abi.decode(proposalArgs, (string, address, uint256,address));
                        _transferTokenFromBank(fromBankName,tokenAddress,value,to);
                    }
                    if (funcHash == keccak256(bytes("mT"))) {
                        (string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) = abi.decode(proposalArgs, (string, string, address, uint256));
                        _moveToken(fromBankName,toBankName,tokenAddress,value);
                    }
                    if (funcHash == keccak256(bytes("iD"))) {
                        (string memory bankName, address tokenAddress, uint256 value) = abi.decode(proposalArgs, (string,address,uint256));
                        _issueDividend(bankName,tokenAddress,value);
                    }
                    if (funcHash == keccak256(bytes("iS"))) {
                        (uint256 amount, address tokenAddress, uint256 price, address to) = abi.decode(proposalArgs, (uint256,address,uint256,address));
                        _issueShards(amount,tokenAddress,price,to);
                    }
                    if (funcHash == keccak256(bytes("dD"))) {
                        (uint256 dividend) = abi.decode(proposalArgs, (uint256));
                        _dissolveDividend(dividend);
                    }
                    if (funcHash == keccak256(bytes("cB"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgs, (string, address));
                        _createBank(bankName,bankAdmin);
                    }
                    if (funcHash == keccak256(bytes("dB"))) {
                        (string memory bankName) = abi.decode(proposalArgs, (string));
                        _deleteBank(bankName);
                    }
                    if (funcHash == keccak256(bytes("aA"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgs, (string, address));
                        _addBankAdmin(bankName,bankAdmin);
                    }
                    if (funcHash == keccak256(bytes("rA"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgs, (string, address));
                        _removeBankAdmin(bankName,bankAdmin);
                    }
                    if (funcHash == keccak256(bytes("rT"))) {
                        (address tokenAddress) = abi.decode(proposalArgs, (address));
                        _registerTokenAddress(tokenAddress);
                    }
                    if (funcHash == keccak256(bytes("uT"))) {
                        (address tokenAddress) = abi.decode(proposalArgs, (address));
                        _unregisterTokenAddress(tokenAddress);
                    }
                    if (funcHash == keccak256(bytes("lE"))) {
                        _liquidize();
                    }
                    else {
                        revert("WF");
                    }
                    emit ActionTaken("iP",abi.encode(referendum,proposalIndex),msg.sender);

        if (amountImplementedByReferendum[referendum] == infoByReferendum[referendum].proposalFuncs.length) {
            emit ReferendumImplemented(referendum);
        }
    }
}