// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.20;

import {Spendable} from "Spendable.sol";

/// @title A standard for interacting with ERC20 tokens.
/// @author Frederik W. L. Christoffersen
abstract contract Managable is Spendable {

	mapping(address => mapping(bytes4 => bytes32)) private _permitByFunctionCall;

	function externalCallPermitOf(address contract, bytes4 sig) public view {
		_permitByFunctionCall[contract][sig];
	}

	function callExternal(address contract, bytes4 sig, bytes args) external onlyPermit(externalCallPermitOf(contract,sig)) {
		_callExternal(contract,sig,args);
	}

	function callPayable(address contract, bytes4 sig, bytes args, uint256 value, bytes32 bank) onlyPermit(bank) onlyPermit(externalCallPermitOf(contract,sig))  {
		_callExternal(contract,sig,args,value,bank)
	}

	function setExternalCallPermit(address contract, bytes4 sig, bytes32 permit) external onlyPermitAdmin(externalCallPermitOf(contract,sig)) {
		_setExternalCallPermit(contract,sig,permit);
	}

	function _callExternal(address contract, bytes4 sig, bytes args, uint256 value, bytes32 bank) internal {
		if (value) {_registerTransferFromBank(bank,address(0),value);}
		contract.call{value:value}(abi.encodePacked(sig,args));
	}

	function _setExternalCallPermit(address contract, bytes4 sig, bytes32 permit) internal {
		_permitByFunctionCall[contract][sig] = permit;
	}

}