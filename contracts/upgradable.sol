pragma solidity ^0.8.4;


/// @title A proxy contract to store a current version contract
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to make another contract upgradeable.
/// @dev This contract is incomplete

contract Upgradable {
	
	address public storedContract;

	constructor() {
		
	}

	function _upgradeTo(string upgradeName) public {
	  require(Upgrader.upgradeIsValid(upgradeName),"Upgrade '"+upgradeName+"' isn't valid!");
        storedContract = newContract;
    }

}

contract Upgrader {
  string[] upgradeNames;
  mapping(string => uint256) upgradeNameIndex;
  mapping(string => bytes) upgradesByName;
  
  modifier onlyCounekt {
    require(msg.sender.address == "counektAddress");
  }
  
  function upgradeIsValid(string upgradeName) external view returns(bool){
    return upgradeNameIndex[upgradeName]>0;
  }
  
  function addUpgrade(string upgradeName, bytes upgradeBytes) external onlyCounekt {
    upgradesByName[upgradeName] = upgradeBytes;
    upgradeNameIndex[upgradeName] = upgradeNames.length + 1;
    upgradeNames.push(upgradeName);
  }
  
  function removeUpgrade(string upgradeName) external onlyCounekt {
    upgradeNames[upgradeNameIndex[upgradeName]-1] = upgradeNames[upgradeNames.length-1];
    upgradeNames.pop();
    upgradeNameIndex[upgradeName] = 0;
  }
}