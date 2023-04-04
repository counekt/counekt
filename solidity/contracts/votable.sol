pragma solidity ^0.8.4;

import "./administrable.sol";

/// @title A fractional DAO-like contract whose decisions can be voted upon by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as a votable administerable business entity.
/// @custom:beaware This is a commercial contract.
contract Votable is Administrable {

    /// @notice Struct representing info of a Referendum.
    /// @param allowDivision Boolean stating if Referendum allows for gradual implementation.
    /// @param proposalFunctionNames Names of functions to be called during implementation.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.
    /// @param forFraction The fraction of Shard-holders who voting FOR the proposals.
    /// @param againstFraction The fraction of Shard-holders who voted AGAINST the proposals.
    /// @param amountImplemented Amount of proposals implemented.
    struct ReferendumInfo {
        bool allowDivision;
        string[] proposalFunctionNames;
        bytes[] proposalArgumentData;
        uint256 favorNumerator;
        uint256 favorDenominator;
        uint256 againstNumerator;
        uint256 againstDenominator;
        uint8 amountImplemented;
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
    /// @param proposalFunctionName The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.    /// @param referendum The passed Referendum from which the Proposal was implemented.
    /// @param by The initiator of the Proposal implementation.
    event ProposalImplemented(
      string proposalFunctionName,
      bytes proposalArgumentData,
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
        require(!hasVoted(referendum, msg.sender));
        _;

    }

    /// @notice Modifier that makes sure a given Referendum is pending.
    /// @param referendum The Referendum to be checked for.
    modifier onlyPendingReferendum(uint256 referendum) {
        require(referendumIsPending(referendum), "RNP");
        _;
    }

    /// @notice Modifier that makes sure a given Referendum is passed.
    /// @param referendum The Referendum to be checked for.
    modifier onlyPassedReferendum(uint256 referendum) {
        require(referendumIsPassed(referendum), "RNT");
        _;
    }

    /// @notice Modifier that makes sure a given Proposal exists within a given Referendum.
    /// @param referendum The Referendum to be checked for.
    /// @param proposalIndex The index of the proposal to be checked for.
    modifier onlyExistingProposal(uint256 referendum, uint8 proposalIndex) {
        require(proposalExists(referendum,proposalIndex), "PNE");
        _;
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param shard The Shard to vote with.
    /// @param referendum The referendum to be voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    function vote(bytes32 shard, uint256 referendum, bool favor) external onlyHistoricShardHolder onlyPendingReferendum(referendum) hasNotVoted(referendum) onlyIfActive {
        require(isHistoricShard(shard), "SNH");
        require(shardExisted(shard,referendum), "SNV");
        hasVotedOnReferendum[referendum][shard] = true;
        if (favor) {
            (uint256 numerator, uint256 denominator) = addFractions(infoByReferendum[referendum].favorNumerator,infoByReferendum[referendum].favorDenominator,infoByShard[shard].numerator,infoByShard[shard].denominator);
            (infoByReferendum[referendum].favorNumerator,infoByReferendum[referendum].favorDenominator) = simplifyFraction(numerator, denominator);
        }
        else {
            (uint256 numerator, uint256 denominator) = addFractions(infoByReferendum[referendum].againstNumerator,infoByReferendum[referendum].againstDenominator,infoByShard[shard].numerator,infoByShard[shard].denominator);
            (infoByReferendum[referendum].againstNumerator,infoByReferendum[referendum].againstDenominator) = simplifyFraction(numerator,denominator);
        }
        emit VoteCast(referendum, favor, msg.sender);
    }

    /// @notice The potential errors of the Proposals aren't checked for before implementation!!!
    /// @param proposalFunctionNames The names of the functions to be called as a result of the implementation of the proposals.
    /// @param proposalArgumentData The parameters passed to the function calls as part of the implementation of the proposals.
    /// @param allowDivision A boolean stating if the proposals of the Referendum are allowed to be incrementally executed.
    function issueVote(string[] memory proposalFunctionNames, bytes[] memory proposalArgumentData, bool allowDivision) public onlyWithPermit("issueVote") onlyIfActive incrementClock {
        uint256 transferTime = clock;
        require(proposalFunctionNames.length == proposalArgumentData.length, "PCW");
        require(transferTime > latestReferendum, "RTY");
        pendingReferendums[transferTime] = true;
        infoByReferendum[transferTime] = ReferendumInfo({
            allowDivision:allowDivision,
            proposalFunctionNames: proposalFunctionNames,
            proposalArgumentData: proposalArgumentData,
            favorNumerator:0,
            favorDenominator:1,
            againstNumerator:0,
            againstDenominator:1,
            amountImplemented: 0
            });
        emit ReferendumIssued(transferTime, msg.sender);
    }

    /// @notice Implements a given Proposal, within a given passed Referendum.
    /// @param referendum The passed Referendum containing the Proposal.
    /// @param proposalIndex The index of the proposal to be implemented.
    function implementProposal(uint256 referendum, uint8 proposalIndex) public onlyWithPermit("implementProposal") onlyIfActive {
        require(infoByReferendum[referendum].allowDivision, "GINA");
        require(infoByReferendum[referendum].amountImplemented == proposalIndex, "WPO");
        infoByReferendum[referendum].amountImplemented += 1;
        string memory proposalFunctionName = infoByReferendum[referendum].proposalFunctionNames[proposalIndex];
        bytes memory proposalArgumentData = infoByReferendum[referendum].proposalArgumentData[proposalIndex];
        bytes32 functionNameHash = keccak256(bytes(proposalFunctionName));
                    if (functionNameHash == keccak256(bytes("issueVote"))) {
                        (string[] memory proposalFunctionNames, bytes[] memory _proposalArgumentData, bool allowDivision) = abi.decode(proposalArgumentData, (string[], bytes[], bool));
                        issueVote(proposalFunctionNames, _proposalArgumentData, allowDivision);
                    }
                    if (functionNameHash == keccak256(bytes("setPermit"))) {
                        (string memory permitName, PermitState newState, address _address) = abi.decode(proposalArgumentData, (string, PermitState,address));
                        setPermit(permitName,newState,_address);
                    }
                    if (functionNameHash == keccak256(bytes("setBasePermit"))) {
                        (string memory permitName, PermitState newState) = abi.decode(proposalArgumentData, (string, PermitState));
                        setBasePermit(permitName,newState);
                    }
                    if (functionNameHash == keccak256(bytes("setNonShardHolderState"))) {
                        (bool newState) = abi.decode(proposalArgumentData, (bool));
                        setNonShardHolderState(newState);
                    }
                    if (functionNameHash == keccak256(bytes("transferToken"))) {
                        (string memory fromBankName, address tokenAddress, uint256 value, address to) = abi.decode(proposalArgumentData, (string, address, uint256,address));
                        transferTokenFromBank(fromBankName,tokenAddress,value,to);
                    }
                    if (functionNameHash == keccak256(bytes("moveToken"))) {
                        (string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) = abi.decode(proposalArgumentData, (string, string, address, uint256));
                        moveToken(fromBankName,toBankName,tokenAddress,value);
                    }
                    if (functionNameHash == keccak256(bytes("issueDividend"))) {
                        (string memory bankName, address tokenAddress, uint256 value) = abi.decode(proposalArgumentData, (string,address,uint256));
                        issueDividend(bankName,tokenAddress,value);
                    }
                    if (functionNameHash == keccak256(bytes("dissolveDividend"))) {
                        (uint256 dividend) = abi.decode(proposalArgumentData, (uint256));
                        dissolveDividend(dividend);
                    }
                    if (functionNameHash == keccak256(bytes("createBank"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        createBank(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("deleteBank"))) {
                        (string memory bankName) = abi.decode(proposalArgumentData, (string));
                        deleteBank(bankName);
                    }
                    if (functionNameHash == keccak256(bytes("addBankAdmin"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        addBankAdmin(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("removeBankAdmin"))) {
                        (string memory bankName, address bankAdmin) = abi.decode(proposalArgumentData, (string, address));
                        removeBankAdmin(bankName,bankAdmin);
                    }
                    if (functionNameHash == keccak256(bytes("liquidize"))) {
                        liquidize();
                    }
        emit ProposalImplemented(proposalFunctionName, proposalArgumentData, referendum, msg.sender);
        if (infoByReferendum[referendum].amountImplemented == infoByReferendum[referendum].proposalFunctionNames.length) {
            emit ReferendumImplemented(referendum);
        }
    }

    /// @notice Returns a boolean stating if a given permit is valid/exists or not.
    /// @param permitName The name of the permit to be checked for.
    function isValidPermit(string memory permitName) override public pure returns(bool) {
            bytes32 permitHash = keccak256(bytes(permitName));
            if (permitHash == keccak256(bytes("setNonShardHolderState"))) {
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
    function hasVoted(uint256 referendum, address _address) public view returns(bool) {
        return hasVotedOnReferendum[referendum][shardByOwner[_address]];
    }

    /// @notice Returns a boolean stating if a given Referendum has been voted through (>=50% FAVOR) or not.
    /// @param referendum The Referendum to be checked for.
    function getReferendumResult(uint256 referendum) public view returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if ((infoByReferendum[referendum].favorNumerator / infoByReferendum[referendum].favorDenominator) * 2 > 1) {
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
    function proposalExists(uint256 referendum, uint8 proposalIndex) public view returns(bool) {
        return infoByReferendum[referendum].proposalFunctionNames.length > proposalIndex;
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

}