pragma solidity ^0.8.20;

import {Spendable} from "./Spendable.sol";

/// @title A standard for interacting with ERC20 tokens.
/// @author Frederik W. L. Christoffersen
abstract contract Managable is Spendable {

	mapping(address => mapping(bytes4 => bytes32)) private _permitByFunctionCall;

	function externalCallPermitOf(address ext, bytes4 sig) public view returns(bytes32) {
		_permitByFunctionCall[ext][sig];
	}

	function callExternal(address ext, bytes4 sig, bytes memory args, uint256 value, bytes32 bank) external onlyPermit(bank) onlyPermit(externalCallPermitOf(ext,sig))  {
		_callExternal(ext,sig,args,value,bank);
	}

	function setExternalCallPermit(address ext, bytes4 sig, bytes32 permit) external onlyPermitAdmin(externalCallPermitOf(ext,sig)) {
		_setExternalCallPermit(ext,sig,permit);
	}

	function _callExternal(address ext, bytes4 sig, bytes memory args, uint256 value, bytes32 bank) internal {
		if (value>0) {_registerTransferFromBank(bank,address(0),value);}
		(bool success,) = ext.call{value:value}(abi.encodePacked(sig,args));
	}

	function _setExternalCallPermit(address ext, bytes4 sig, bytes32 permit) internal {
		_permitByFunctionCall[ext][sig] = permit;
	}

}