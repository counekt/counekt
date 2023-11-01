// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Redeemable} from "../utils/Redeemable.sol";

abstract contract ERC360Redeemable is ERC360, Redeemable {

    mapping(uint256 => uint256) private _clockByEventId;

    function clockOf(uint256 eventId) public view returns(uint256) {
        return _clockByEventId[eventId];
    }

    function _createEvent() virtual override internal returns(uint256) {
        uint256 eventId = Redeemable._createEvent();
        _clockByEventId[eventId] = currentClock();
        return eventId;
    }
}