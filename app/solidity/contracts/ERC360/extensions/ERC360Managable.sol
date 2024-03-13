// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Spendable} from "../utils/Spendable.sol";
import {Managable} from "../utils/Managable.sol";
import {ERC20Holder} from "../utils/ERC20Holder.sol";

abstract contract ERC360Managable is ERC360, Managable {

    constructor(string memory name_, string memory symbol_) ERC360(name_,symbol_) {
        _setPermit(_msgSender(),bytes32(0),true); // grant the master permit to creator
    }

    function mint(address account, uint256 amount) external onlyPermit(keccak256("MINT")) {
        _mint(account,amount);
    }

}
