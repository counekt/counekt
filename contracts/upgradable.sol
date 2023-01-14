pragma solidity ^0.8.4;


// @title A proxy contract to store a current version contract
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to make another contract upgradeable.
/// @dev All function calls are currently implemented without side effects

contract Upgradable {
	
	address public storedContract;

	constructor() {
		
	}

	function _upgradeTo(address _newContract) public {
        storedContract = _newContract;
    }

}