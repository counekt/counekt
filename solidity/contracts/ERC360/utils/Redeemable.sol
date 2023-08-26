// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

abstract contract Redeemable {

    using Counters for Counters.Counter;

    Counters.Counter private _eventIdClock;

    mapping(uint256 => mapping(uint256 => bool)) private _tokenIdHasRedeemedEventId;

    error ReedeemableAlreadyRedeemed(uint256,uint256);

    function hasRedeemed(uint256 tokenId,uint256 eventId) public view returns(bool){
        return _tokenIdHasRedeemedEventId[tokenId][eventId];
    }

    function _requireUnredeemed(uint256 tokenId, uint256 eventId) internal {
        if (hasRedeemed(tokenId, eventId)) {revert ReedeemableAlreadyRedeemed(tokenId,eventId);}
    }
    
    function _redeemEvent(uint256 tokenId, uint256 eventId) internal {
        _tokenIdHasRedeemedEventId[tokenId][eventId] = true;
    }

    function _createEvent() virtual internal returns(uint256) {
        _eventIdClock.increment();
        return _eventIdClock.current();
    }

}