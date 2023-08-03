// SPDX-License-Identifier: GPL-3.0-or-later
import "../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Receiver {
	function receiveToken(address tokenAddress, uint256 amount) external {}
}

error ERC20InvalidReceiver(address);

/// @title A standard for interacting with ERC20 tokens.
/// @author Frederik W. L. Christoffersen
abstract contract ERC20Holder is IERC20Receiver {

	using SafeERC20 for IERC20;

    /// @notice Receives a token and registers the transaction. 
    /// @dev Make sure 'token.approve()' is called by sender beforehand.
    /// @param tokenAddress The address of the token to be received.
    /// @param value The amount of the token to be received.
	function receiveToken(address tokenAddress, uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender,address(this),amount);
        _processTokenReceipt(tokenAddress,amount);
	}

    /// @notice Transfers a token to a recipient.
	/// @param tokenAddress The address of the token to be transferred.
    /// @param amount The amount of the token to be transferred.
    /// @param to The recipient of the transfer.
	function _transferToken(address to, address tokenAddress, uint256 amount) internal {
		IERC20 token = IERC20(tokenAddress);
		if (to.code.length > 0) {
			token.safeApprove(to,amount);
			try {to.receiveToken(tokenAddress,amount);} catch {revert ERC20InvalidReceiver(to);}
		}
		else {token.safeTransfer(to,amount)}
		_processTokenTransfer(to,tokenAddress,amount);
	}

	function _processTokenReceipt(address tokenAddress, uint256 amount) virtual internal {}

	function _processTokenTransfer(address to, address tokenAddress, uint256 amount) virtual internal{}
}