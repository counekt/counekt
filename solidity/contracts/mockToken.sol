// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockToken is ERC20 {

	constructor() ERC20("Test Token", "TST") {}

	function mint(address account, uint256 amount) public {
		_mint(account, amount);
	}
}