// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC360} from "./IERC360.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC360 standard.
 */
interface IERC360Metadata is IERC360 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}