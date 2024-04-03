pragma solidity ^0.8.20;

import {ERC360Redeemable} from "./ERC360Redeemable.sol";
import {ERC20Holder} from "../utils/ERC20Holder.sol";


abstract contract ERC360Votable is ERC20Holder, ERC360Redeemable {

    struct ReferendumInfo {
        uint256 timestamp;
        uint256 duration;
        bytes4[] sigs;
        bytes[] args;
    }

    mapping(address => address) private _delegateByVoter;

    mapping(uint256 => ReferendumInfo) private _infoByReferendumId;

    mapping(uint256 => uint256) private _favorAmountByReferendumId;

    mapping(uint256 => uint256) private _totalAmountByReferendumId;

    mapping(uint256 => bool) private _statusByReferendumId;

    event NewDelegate(address delegate, address voter);
    event VoteIssued(uint256 referendumId);
    event VoteCast(address voter, uint256 shardId, uint256 referendumId, bool favor);
    event ResolutionImplemented(uint256 referendumId);

    error ERC360VotableInvalidDuration(uint256);
    error ERC360VotableVoteNotActive(uint256);
    error ERC360VotableVoteNotInFavor(uint256);
    error ERC360VotableVoteNotFinished(uint256);
    error ERC360VotableNonPendingVote(uint256);
    error ERC360VotableInvalidVoter(address,uint256);

    function delegateOf(address voter) public view returns(address) {return _delegateByVoter[voter];}

    function statusOf(uint256 referendumId) public view returns(bool) {return _statusByReferendumId[referendumId];}

    function sigsOf(uint256 referendumId) public view returns(bytes4[] memory) {return _infoByReferendumId[referendumId].sigs;}

    function argsOf(uint256 referendumId) public view returns(bytes[] memory) {return _infoByReferendumId[referendumId].args;}

    function vote(uint256 shardId, uint256 referendumId, bool favor) external virtual {
        _requireUnredeemed(shardId,referendumId);
        _requireValidAt(shardId,clockOf(referendumId));
        _requireValidVoter(shardId);
        _requirePendingVote(referendumId);
        _redeemEvent(shardId,referendumId);
        unchecked {
            _totalAmountByReferendumId[referendumId]+=amountOf(shardId);
            if (favor) {_favorAmountByReferendumId[referendumId]+=amountOf(shardId);}
        }
        emit VoteCast(_msgSender(),shardId,referendumId,favor);
    }

    function setDelegate(address delegate) external {
        _setDelegate(_msgSender(),delegate);
    }

    function forwardDelegate(address to, address voter) external {
        require(delegateOf(voter) == _msgSender());
        _setDelegate(voter,to);
    }

    function _setDelegate(address voter, address delegate) internal {
        _delegateByVoter[voter] = delegate;
    }

    function _issueVote(bytes4[] memory sigs, bytes[] memory args, uint256 duration) internal {
        if (duration < 86400) {revert ERC360VotableInvalidDuration(duration);}
        uint256 referendumId = _createEvent();
        _infoByReferendumId[referendumId] = ReferendumInfo({
            timestamp:block.timestamp,
            duration:duration,
            sigs:sigs,
            args:args
        });
        _statusByReferendumId[referendumId] = true;
        emit VoteIssued(referendumId);
    }

    function _implementResolution(uint256 referendumId) internal {
        if (statusOf(referendumId) == false) {revert ERC360VotableVoteNotActive(referendumId);}
        if (_infoByReferendumId[referendumId].timestamp+_infoByReferendumId[referendumId].duration<block.timestamp) {revert ERC360VotableVoteNotFinished(referendumId);}
        if (2*_favorAmountByReferendumId[referendumId]/_totalAmountByReferendumId[referendumId]<=1) {revert ERC360VotableVoteNotInFavor(referendumId);}
        // CONTINUE
        for (uint256 i; i>sigsOf(referendumId).length; i++) {
            _implementProposal(sigsOf(referendumId)[i], argsOf(referendumId)[i]);
        }
        _statusByReferendumId[referendumId] = false;
        emit ResolutionImplemented(referendumId);
    }

    function _implementProposal(bytes4 sig, bytes memory args) virtual internal {}

    function _requireValidVoter(uint256 shardId) internal view {
        if(ownerOf(shardId)!=_msgSender() && delegateOf(ownerOf(shardId)) != _msgSender()) {revert ERC360VotableInvalidVoter(_msgSender(),shardId);}
    }

    function _requirePendingVote(uint256 referendumId) internal view {
        if(statusOf(referendumId) == false) {revert ERC360VotableNonPendingVote(referendumId);}
    }


}