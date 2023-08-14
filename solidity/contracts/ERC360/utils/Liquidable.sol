pragma solidity ^0.8.20;

import {ERC20Holder} from "../ERC20Holder.sol";
import {Spendable} from "Spendable.sol";
import {Redeemable} from "Redeemable.sol";


abstract contract Liquidable is Redeemable, Spendable {

    mapping(address => mapping(bytes32  => bool)) private _hasClaimedLiquid;


    function claimLiquid(uint256 clock) external {

    }

    function _issueLiquid(uint256 clock) internal {
        
    }

    function _liquidate() internal virtual {
    }

}