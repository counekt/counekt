pragma solidity ^0.8.4;


/// @title A proxy contract to store a current version contract
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to make another contract upgradeable.
/// @dev This contract is incomplete
contract UpgradableProxy {
	
	address public agent;

	constructor(string versionName) {
		_upgradeTo(versionName);
	}

	fallback() external payable {
		agent.delegatecall(msg.data);
	}

	function _upgradeTo(string versionName) public {
	  require(Upgrader.upgradeIsValid(versionName),"Version '"+versionName+"' doesn't exist!");
	   address newAgentContract = address(create(Upgrader.versionsByName[versionName]));
        agent = newAgentContract;
    }

}

/// @title Bottle neck of the upgradability. An admin contract to manage valid Idea entity upgrades controlled by Counekt.
/// @author Frederik W. L. Christoffersen
/// @notice This contract will only have one instance, whose address will be used by the UpgradableProxy.
/// @dev This contract needs to be deployed with one instance before the other ones.
contract Upgrader {
  string[] versionNames;
  mapping(string => uint256) versionNameIndex;
  mapping(string => bytes) versionsByName;
  
  modifier onlyCounekt {
    require(msg.sender.address == 0x49a71890aea5A751E30e740C504f2E9683f347bC);
  }
  
  function versionIsValid(string upgradeName) external view returns(bool){
    return versionNameIndex[versionName]>0;
  }
  
  function addVersion (string versionName, bytes versionBytes) external onlyCounekt {
    versionByName[versionName] = versionBytes;
    versionNameIndex[versionName] = versionNames.length + 1;
    versionNames.push(versionName);
  }
  
  function removeUpgrade(string versionName) external onlyCounekt {
    versionNames[versionNameIndex[versionName]-1] = versionNames[versiomNames.length-1];
    versionNames.pop();
    versionNameIndex[versionName] = 0;
  }
}