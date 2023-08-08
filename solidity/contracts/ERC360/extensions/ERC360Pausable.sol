pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Pausable} from "../../@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev ERC360 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract pause mechanism of the contract unreachable, and thus unusable.
 */
abstract contract ERC360Pausable is ERC360, Pausable {
    /**
     * @dev See {ERC360-_update}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _update(address account, uint256 amount) internal virtual override whenNotPaused {
        super._update(account, amount);
    }

}