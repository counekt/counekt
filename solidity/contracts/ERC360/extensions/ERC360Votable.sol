pragma solidity ^0.8.20;

import {ERC360Redeemable} from "ERC360Redeemable.sol";

abstract contract ERC360Votable is ERC360Redeemable {

    struct VoteInfo {
        uint256 timestamp;
        uint256 duration;
        bytes4[] sigs;
        bytes[] args;
    }

    mapping(address => address) private _delegateByAccount;

    mapping(uint256 => VoteInfo) private _infoByVoteId;

    mapping(uint256 => uint256) private _favorAmountByVoteId;

    mapping(uint256 => uint256) private _totalAmountByVoteId;

    mapping(uint256 => bool) private _statusByVoteId;

    event NewDelegate(address delegate, address voter);
    event VoteIssued(uint256 voteId);
    event VoteCast(address voter, uint256 tokenId, uint256 voteId, bool favor);
    event ResolutionImplemented(uint256 voteId);

    function delegateOf(address voter) public view returns(address) {return _delegateByVoter[voter];}

    function statusOf(uint256 voteId) public view returns(bool) {return _statusByVoteId[voteId];}

    function sigsOf(uint256 voteId) public view returns(bytes4[]) {return _infoByVoteId[voteId].sigs;}

    function argsOf(uint256 voteId) public view returns(bytes[]) {return _infoByVoteId[voteId].args;}

    function vote(uint256 tokenId, uint256 voteId, bool favor) external virtual {
        _requireUnredeemed(tokenId,voteId);
        _requireValidAt(tokenId,clockOf(voteId));
        _requireValidVoter(tokenId);
        _requirePendingVote(voteId);
        _redeemEvent(tokenId,voteId);
        unchecked {
            _totalAmountByVote[voteId]+=amountOf(tokenId);
            if (favor) {_favorAmountByVote[voteId]+=amountOf(tokenId);}
        }
        emit VoteCast(_msgSender(),tokenId,voteId,favor);
    }

    function setDelegate(address delegate) external {
        _setDelegate(_msgSender(),delegate);
    }

    function forwardDelegate(address to, address account) external {
        require(delegateOf(account) == _msgSender());
        _setDelegate(account,to);
    }

    function _setDelegate(address account, address delegate) {
        _delegateByAccount[account] = delegate;
    }

    function _issueVote(bytes4[] sigs, bytes[] args, uint256 duration) {
        if (duration < 86400) {revert ERC360VotableInvalidDuration(duration);}
        uint256 voteId = _createEvent();
        _infoByVoteId[voteId] = VoteInfo({
            timestamp:block.timestamp,
            duration:duration,
            sigs:sigs,
            args:args
        });
        _statusByVoteId[voteId] = true;
        emit VoteIssued(voteId);
    }

    function _implementResolution(uint256 voteId) {
        if (statusOf(voteId) == false) {revert ERC360VotableVoteNotActive(voteId);}
        if (_infoByVoteId[voteId].timestamp+_infoByVoteId[voteId].duration<block.timestamp) {revert ERC360VotableVoteNotFinished(voteId);}
        if (2*_favorAmountByVoteId[voteId]/_totalAmountByVoteId[voteId]<=1) {revert ERC360VotableVoteNotInFavor(voteId);}
        // CONTINUE
        for (i; i>sigsOf(voteId).length; i++) {
            _implementProposal(sigsOf(voteId)[i], argsOf(voteId)[i]));
        }
        _statusByVoteId[voteId] = false;
        emit ResolutionImplemented(voteId);
    }

    function _implementProposal(bytes4 sig, bytes args) virtual internal {}

    function _requireValidVoter(uint256 tokenId) internal view {
        if(ownerOf(tokenId)!=_msgSender() && delegateOf(ownerOf(tokenIdOf)) != _msgSender()) {revert ERC360VotableInvalidVoter(_msgSender(),tokenId);}
    }

    function _requirePendingVote(uint256 voteId) internal view {
        if(statusOf(voteId) == false) {revert ERC360VotableNonPendingVote(voteId);}
    }


}