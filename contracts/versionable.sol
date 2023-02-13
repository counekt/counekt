pragma solidity ^0.8.4;

/*
/// @title A proxy contract to store a current version contract
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to make another contract upgradeable.
/// @dev This contract is incomplete
contract Versionable {
	
	address forwardsTo;
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
*/

/// @title Bottle neck of the Administration versioning. An admin contract to manage valid Idea entity upgrades controlled by Counekt.
/// @author Frederik W. L. Christoffersen
/// @notice This contract will only have one instance, whose address will be used by the UpgradableProxy.
/// @dev This contract needs to be deployed as one instance before all other ones.
contract VersionAdmin {

	constructor() {
		versionNameIndex["Administration"] = 1; 
		versionNameIndex["Votable"] = 1; 


	}
  string[] versionNames = ["Administration", "Votable"];
  mapping(string => uint256) versionNameIndex;
  mapping(string => address) versionByName;
  
  modifier onlyCounekt {
    require(msg.sender.address == 0x49a71890aea5A751E30e740C504f2E9683f347bC);
  }

  modifier onlyValidVersion(string versionName) {
  	require(versionIsValid(versionName),"Version '"+versionName+"' isn't valid!");
  }
  
  function versionIsValid(string versionName) external view returns(bool){
    return versionNameIndex[versionName]>0;
  }

  function createVersion(string versionName) external returns(address) onlyValidVersion(versionName) {
  	address newVersionInstance = address(uint160(keccak256(abi.encodePacked(versionByName[versionName]))));
  	newVersionInstance.deploy(versionByName[versionName]);
  	return newVersionInstance;
  }
  
  function addVersion(string versionName, bytes versionBytes) external onlyCounekt {
    versionByName[versionName] = versionBytes;
    versionNameIndex[versionName] = versionNames.length + 1;
    versionNames.push(versionName);
  }
  
  function removeVersion(string versionName) external onlyCounekt {
    versionNames[versionNameIndex[versionName]-1] = versionNames[versiomNames.length-1];
    versionNames.pop();
    versionNameIndex[versionName] = 0;
  }
}

