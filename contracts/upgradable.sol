pragma solidity ^0.8.4;


/// @title A proxy contract to store a current version contract
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to make another contract upgradeable.
/// @dev This contract is incomplete
contract UpgradableProxy {
	
	address public agent;

	constructor(address) {
		
	}

	fallback() external payable {
		agent.delegatecall(msg.data);
	}

	function _upgradeTo(string upgradeName) public {
	  require(Upgrader.upgradeIsValid(upgradeName),"Upgrade '"+upgradeName+"' isn't valid!");
	   address newAgentContract = address(create(Upgrader.upgradesByName[upgradeName]));
        agent = newAgentContract;
    }

}

/// @title Bottle neck of the upgradability. An admin contract to manage valid Idea entity upgrades controlled by Counekt.
/// @author Frederik W. L. Christoffersen
/// @notice This contract will only have one instance, whose address will be used by the UpgradableProxy.
/// @dev This contract needs to be deployed with one instance before the other ones.
contract Upgrader {
  string[] upgradeNames;
  mapping(string => uint256) upgradeNameIndex;
  mapping(string => bytes) upgradesByName;
  
  modifier onlyCounekt {
    require(msg.sender.address == 0x49a71890aea5A751E30e740C504f2E9683f347bC);
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