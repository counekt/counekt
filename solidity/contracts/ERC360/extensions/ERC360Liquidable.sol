pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Spendable} from "Spendable.sol";
import {Redeemable} from "Redeemable.sol";


abstract contract ERC360Liquidable is ERC360, Redeemable, Spendable {

    mapping(address => mapping(bytes32 => bool)) private _hasClaimedLiquid;


    function claimLiquid(uint256 clock) external {

    }

    function _issueDividend(uint256 clock) internal {
        
    }

    function _liquidate() internal virtual {
    }

}