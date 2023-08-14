// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;


import "../@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A standard for interacting with ERC20 tokens.
/// @author Frederik W. L. Christoffersen
abstract contract ERC20Holder {

	using SafeERC20 for IERC20;

    /// @notice Transfers a token to a recipient.
	/// @param tokenAddress The address of the token to be transferred.
    /// @param amount The amount of the token to be transferred.
    /// @param to The recipient of the transfer.
	function _transferToken(address to, address tokenAddress, uint256 amount) internal {
		IERC20 token = IERC20(tokenAddress);
		else {token.safeTransfer(to,amount)}
	}

}