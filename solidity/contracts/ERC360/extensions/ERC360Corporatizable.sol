pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Administrable} from "../utils/Administrable.sol";
import {Liquidable} from "../utils/Liquidable.sol";
import {Votable} from "../utils/Votable.sol";

abstract contract ERC360Corporatizable is ERC360, Administrable, Liquidable, Spendable, Votable {
    /**
     * @dev See {ERC360-_update}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */

}