// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A standard for interacting with ERC20 tokens.
/// @author Frederik W. L. Christoffersen
abstract contract ERC20Holder {

	using SafeERC20 for IERC20;

    /// @notice Transfers a token to a recipient.
	/// @param token The address of the token to be transferred.
    /// @param amount The amount of the token to be transferred.
    /// @param to The recipient of the transfer.
	function _transferToken(address to, address token, uint256 amount) internal {
		// IERC20 token = IERC20(token);
		IERC20(token).safeTransfer(to,amount);
	}

	function _transferFunds(address to, address token, uint256 amount) internal {
        if (token == address(0)) {
        (bool success, ) = address(to).call{value:amount}("");
        require(success);
        }
        else {_transferToken(to,token,amount);}
    }
}