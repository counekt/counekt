// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./administrable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    enum ReferendumStatus {
        inactive,
        pending,
        passed
    }

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

    /// @notice Mapping pointing to a an enum showing the ReferendumStatus of a Referendum.
    mapping(uint256 => ReferendumStatus) statusByReferendum;

    /// @notice Event that triggers when a Referendum is closed.
    /// @param referendum The passed Referendum that was closed.
    /// @param passed Boolean signifying if the referendum was passed or not.
    event ReferendumClosed(
        uint256 referendum,
        bool passed
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

    constructor(uint256 amount) Administrable(amount) {
        _setPermit("iR",msg.sender,PermitState.administrator);
        _setPermit("iP",msg.sender,PermitState.administrator);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param shard The Shard to vote with.
    /// @param referendum The referendum to be voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    function vote(bytes32 shard, uint256 referendum, bool favor) external onlyHolder(shard) onlyIfActive {
        require(statusByReferendum[referendum] == ReferendumStatus.pending, "RNP");
        require(!hasActionCompleted[referendum][shard]);
        require(shardExisted(shard,referendum), "SNV");
        hasActionCompleted[referendum][shard] = true;
        if (favor) {
            favorAmountByReferendum[referendum] += infoByShard[shard].amount;
        }
        totalAmountByReferendum[referendum] += infoByShard[shard].amount;
        
        emit VoteCast(referendum, favor, msg.sender);
        if ((favorAmountByReferendum[referendum] / totalShardAmountByClock[referendum]) * 2 > 1) {
            statusByReferendum[referendum] = ReferendumStatus.passed;
            emit ReferendumClosed(referendum,true);

        }
        else if (((totalAmountByReferendum[referendum] - favorAmountByReferendum[referendum]) / totalShardAmountByClock[referendum]) * 2 > 1) {

            statusByReferendum[referendum] = ReferendumStatus.inactive;
            emit ReferendumClosed(referendum,false);
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
        statusByReferendum[clock] = ReferendumStatus.pending;
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
        require(statusByReferendum[referendum] == ReferendumStatus.passed);
        require(proposalExists(referendum,proposalIndex),"PDE");
        require(amountImplementedByReferendum[referendum] == proposalIndex, "WPO");
        amountImplementedByReferendum[referendum] += 1;
        string memory proposalFunc = infoByReferendum[referendum].proposalFuncs[proposalIndex];
        bytes memory proposalArgs = infoByReferendum[referendum].proposalArgs[proposalIndex];
        bytes32 funcHash = keccak256(bytes(proposalFunc));
                    if (funcHash == keccak256(bytes("iR"))) {
                        (string[] memory proposalFuncs, bytes[] memory _proposalArgs) = abi.decode(proposalArgs,(string[],bytes[]));
                        _issueReferendum(proposalFuncs, _proposalArgs);
                    }
                    if (funcHash == keccak256(bytes("sP"))) {
                        (string memory permitName, address account, PermitState newState) = abi.decode(proposalArgs,(string,address,PermitState));
                        _setPermit(permitName,account,newState);
                    }
                    if (funcHash == keccak256(bytes("tF"))) {
                        (string memory fromBankName, address to, address tokenAddress, uint256 amount) = abi.decode(proposalArgs,(string,address,address,uint256));
                        _transferFundsFromBank(fromBankName,to,tokenAddress,amount);
                    }
                    if (funcHash == keccak256(bytes("mF"))) {
                        (string memory fromBankName, string memory toBankName, address tokenAddress, uint256 amount) = abi.decode(proposalArgs,(string,string,address,uint256));
                        _moveToken(fromBankName,toBankName,tokenAddress,amount);
                    }
                    if (funcHash == keccak256(bytes("iD"))) {
                        (string memory bankName, address tokenAddress, uint256 value) = abi.decode(proposalArgs,(string,address,uint256));
                        _issueDividend(bankName,tokenAddress,value);
                    }
                    if (funcHash == keccak256(bytes("iS"))) {
                        (uint256 amount, address tokenAddress, uint256 price, address to) = abi.decode(proposalArgs,(uint256,address,uint256,address));
                        _issueShards(amount,tokenAddress,price,to);
                    }
                    if (funcHash == keccak256(bytes("dD"))) {
                        (uint256 dividend) = abi.decode(proposalArgs,(uint256));
                        _dissolveDividend(dividend);
                    }
                    if (funcHash == keccak256(bytes("cB"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgs, (string,address));
                        _createBank(bankName,bankAdmin);
                    }
                    if (funcHash == keccak256(bytes("sBA"))) {
                        (string memory bankName,address admin,bool status) = abi.decode(proposalArgs,(string,address,bool));
                        _setBankAdminStatus(bankName,admin,status);
                    }
                    if (funcHash == keccak256(bytes("sTS"))) {
                        (address tokenAddress, bool status) = abi.decode(proposalArgs,(address,bool));
                        _setTokenStatus(tokenAddress,status);
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