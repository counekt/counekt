pragma solidity ^0.8.20;

import {ERC20Holder} from "../ERC20Holder.sol";

abstract contract Redeemable {

    using Counters for Counters.Counter;

    Counters.Counters private _eventIdClock;

    mapping(uint256 => mapping(uint256 => bool)) private _tokenIdHasRedeemedEventId;

    function hasRedeemed(uint256 tokenId,uint256 eventId) public view returns(bool){
        return _tokenIdHasRedeemedEventId[tokenId][eventId];
    }

    function _requireUnredeemed(uint256 tokenId, uint256 eventId) internal {
        if (hasRedeemed(tokenId, eventId)) {revert ReedeemableAlreadyRedeemed(tokenId,eventId);}
    }
    
    function _redeemEvent(uint256 tokenId, uint256 eventId) internal {
        _tokenIdHasRedeemedEventId[tokenId][eventId] = true;
    }

    function _createEvent() returns(uint256) {
        _eventIdClock.increment();
        return _eventIdClock.current();
    }

}