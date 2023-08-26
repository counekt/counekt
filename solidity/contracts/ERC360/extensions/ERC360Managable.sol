// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC360} from "contracts/ERC360/ERC360.sol";
import {Spendable} from "contracts/ERC360/utils/Spendable.sol";
import {Managable} from "contracts/ERC360/utils/Managable.sol";

abstract contract ERC360Managable is ERC360, Managable {

    constructor(uint256 amount, string memory name_, string memory symbol_) ERC360(name_,symbol_) {
        _mint(_msgSender(),amount); // mint the initial supply to creator
        _setPermit(_msgSender(),bytes32(0),true); // grant the master permit to creator
    }

    function mint(address account, uint256 amount) external onlyPermit(keccak256("MINT")) {
        _mint(account,amount);
    }

}
