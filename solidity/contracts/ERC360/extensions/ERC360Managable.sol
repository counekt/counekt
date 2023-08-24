pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Spendable} from "../utils/Spendable.sol";
import {Callable} from "../utils/Callable.sol";

abstract contract ERC360Managable is ERC360, Spendable, Callable {


    constructor(uint256 amount, string memory name_, string memory symbol_) ERC360(name_,symbol_) {
        _mint(_msgSender(),amount); // mint the initial supply to creator
        _setPermit(_msgSender(),bytes32(0),true); // grant the master permit to creator
    }


    function claimLiquid(uint256 clock) external {

    }

    function _issueDividend(uint256 clock) internal {
        
    }

    function _liquidate() internal virtual {
    }

}

