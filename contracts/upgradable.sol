pragma solidity ^0.8.4;

contract Upgradable {
	
	address public storedContract;

	constructor() {
		
	}

	function _upgradeTo(address _newContract) public {
        storedContract = _newContract;
    }

}