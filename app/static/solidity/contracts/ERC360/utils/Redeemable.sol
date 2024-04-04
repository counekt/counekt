pragma solidity ^0.8.20;

import {Counters} from "node_modules/@openzeppelin/contracts/utils/Counters.sol";

abstract contract Redeemable {

    using Counters for Counters.Counter;

    Counters.Counter private _eventClock;

    mapping(uint256 => mapping(uint256 => bool)) private _shardHasRedeemedEvent;

    error ReedeemableAlreadyRedeemed(uint256,uint256);

    function hasRedeemed(uint256 shardId,uint256 eventId) public view returns(bool){
        return _shardHasRedeemedEvent[shardId][eventId];
    }

    function _requireUnredeemed(uint256 shardId, uint256 eventId) internal {
        if (hasRedeemed(shardId, eventId)) {revert ReedeemableAlreadyRedeemed(shardId,eventId);}
    }
    
    function _redeemEvent(uint256 shardId, uint256 eventId) internal {
        _shardHasRedeemedEvent[shardId][eventId] = true;
    }

    function _createEvent() virtual internal returns(uint256) {
        _eventClock.increment();
        return _eventClock.current();
    }

}