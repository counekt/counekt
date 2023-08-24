pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Redeemable} from "Redeemable.sol";

abstract contract ERC360Votable is ERC360, Redeemable {

    struct ReferendumInfo {
        uint256 clock,
        uint256 blockTimestamp;
        uint256 duration;
        bytes4[] sigs;
        bytes[] args;
    }

    mapping(address => address) private _delegateByAccount;

    mapping(uint256 => ReferendumInfo) private _infoByReferendumId;

    mapping(uint256 => uint256) private _favorAmountByReferendumId;

    mapping(uint256 => uint256) private _totalAmountByReferendumId;

    mapping(uint256 => bool) private _statusByReferendumId;


    event NewDelegate(address delegate, address voter);
    event VoteIssued(uint256 referendumId);
    event VoteCast(address voter, uint256 tokenId, uint256 referendumId, bool favor);
    event ResolutionImplemented(uint256 referendumId);

    function delegateOf(address voter) public view returns(address) {return _delegateByVoter[voter];}

    function statusOf(uint256 referendumId) public view returns(bool) {return _statusByReferendum[referendumId];}

    function clockOf(uint256 referendumId) public view returns(uint256) {return _infoByReferendumId[referendumId].clock;}

    function sigsOf(uint256 referendumId) public view returns(bytes4[]) {return _infoByReferendumId[referendumId].sigs;}

    function argsOf(uint256 referendumId) public view returns(bytes[]) {return _infoByReferendumId[referendumId].args;}

    function vote(uint256 tokenId, uint256 referendumId, bool favor) external virtual {
        _requireUnredeemed(tokenId,referendumId);
        if(statusOf(referendumId) == false) {revert ERC360VotableNonPendingReferendum(referendumId);}
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

    function _issueVote(bytes4[] sigs, bytes[] args, uint256 duration) {
        if (duration < 86400) {revert ERC360VotableInvalidDuration(duration);}
        uint256 referendumId = _createEvent();
        _infoByReferendum[referendumId] = ReferendumInfo({
            clock:currentClock(),
            blockTimestamp:block.timestamp,
            duration:duration,
            sigs:sigs,
            args:args
        });
        _statusByReferendumId[referendumId] = true;
        emit VoteIssued(referendumId);
    }

    function _implementResolution(uint256 referendumId) {
        if (statusOf(referendumId) == false) {revert ERC360VotableVoteNotActive(referendumId);}
        if (_infoByReferendumId[referendumId].blockTimestamp+_infoByReferendumId[referendumId].duration<block.timestamp) {revert ERC360VotableVoteNotFinished(referendumId);}
        if (2*_favorAmountByReferendumId[referendumId]/_totalAmountByReferendumId[referendumId]<=1) {revert ERC360VotableVoteNotInFavor(referendumId);}
        // CONTINUE
        for (i; i>sigsOf(referendumId).length; i++) {
            _implementProposal(sigsOf(referendumId)[i], argsOf(referendumId)[i]));
        }
        _statusByReferendumId[referendumId] = false;
        emit ResolutionImplemented(referendumId);
    }

    function _implementProposal(bytes4 sig, bytes args) virtual internal {}


}