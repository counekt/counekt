pragma solidity ^0.8.20;

import {ERC20Holder} from "../ERC20Holder.sol";

abstract contract Liquidable is ERC20Holder {

    function _liquidate() internal virtual {}

    function claimLiquid(uint256 clock) external 

}