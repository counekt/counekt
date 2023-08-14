pragma solidity ^0.8.20;

import {Redeemable} from "Redeemable.sol";

abstract contract ERC360Votable is ERC360, Redeemable {

    enum ReferendumStatus {
        inactive,
        pending,
        passed
    }

    struct ReferendumInfo {
        uint256 blockTimestamp;
        uint256 duration;
        bytes4[] proposalSigs;
        bytes[] proposalArgs;
    }

    mapping(address => address) private _delegateByAccount;

    mapping(uint256 => ReferendumInfo) private _infoByReferendumId;

    mapping(uint256 => uint256) private _favorAmountByReferendumId;

    mapping(uint256 => uint256) private _totalAmountByReferendumId;

    mapping(uint256 => ReferendumStatus) private _statusByReferendumId;


    event NewDelegate(address delegate, address voter);
    event VoteIssued(uint256 referendumId);
    event VoteCast(address voter, uint256 tokenId, uint256 referendumId, bool favor);

    function delegateOf(address voter) public view returns(address) {
        return _delegateByVoter[voter];
    }

    function statusOf(uint256 referendumId) public view returns(uint256) {
        return _statusByReferendum[referendumId];
    }

    function clockOf(uint256 referendumId) public view returns(uint256) {
        return _infoByReferendumId[referendumId].clock;
    }

    function vote(uint256 tokenId, uint256 referendumId, bool favor) external virtual {
        _requireUnredeemed(tokenId,referendumId);
        if(statusOf(referendumId) != ReferendumStatus.pending) {revert ERC360VotableNonPendingReferendum(referendumId);}
        if(ownerOf(tokenId)!=_msgSender() && delegateOf(ownerOf(tokenIdOf)) != _msgSender()) {revert ERC360VotableInvalidVoter(_msgSender(),tokenId);}
        if(!wasValid(tokenId,clockOf(referendumId))) {revert ERC360VotableInvalidTokenId(tokenId,referendumId);}
        unchecked {
        if (favor) {_favorAmountByReferendum[referendumId]+=amountOf(tokenId);}
        _totalAmountByReferendum[referendumId]+=amountOf(tokenId);
        }
        _redeemEvent(tokenId,referendumId);
        emit VoteCast(_msgSender(),tokenId,referendumId,favor);
    }

    function setDelegate(address delegate) external {
        _delegateByAccount[_msgSender()] = delegate;
    }

    function forwardDelegate(address to, address account) external {
        require(delegateOf(account) == _msgSender());
        _delegateByAccount[account] = to;
    }

    function _issueVote(bytes4[] proposalSigs, bytes[] proposalArgs, uint256 duration) {
        if (duration < 86400) {revert ERC360VotableInvalidDuration(duration);}
        uint256 referendumId = _createEvent();
        _infoByReferendum[referendumId] = ReferendumInfo({
            blockTimestamp:block.timestamp,
            duration:duration,
            proposalSigs:proposalSigs,
            proposalArgs:proposalArgs
        });
        _statusByReferendumId[referendumId] = ReferendumStatus.pending;
        emit VoteIssued(referendumId);
    }


}