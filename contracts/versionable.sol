pragma solidity ^0.8.4;

import "../administable.sol";


/// @title Bottle neck of the Administrable versioning. An admin contract to manage valid Idea entity upgrades controlled by Counekt.
/// @author Frederik W. L. Christoffersen
/// @notice This contract will only have one instance, whose address will be used by the UpgradableProxy.
/// @dev This contract needs to be deployed as one instance before all other ones.
/// @dev NEXT UP => build Administrable up from another 

contract AdministrableVersioner {

  /// @notice Mapping pointing to boolean stating if a version is valid given its name.
  mapping(string => bool) validVersions;
  /// @notice Mapping pointing to an address of a version given its name.
  mapping(string => address) versionByName;

  /// @notice Event that triggers when a new version is added.
  event newVersion(string name, address version);

  /// @notice Event that triggers when a former version gets deprecated.
  event depricatedVersion(string name, address version);
  
  /// @notice Modifier requiring the msg.sender to be that of Counekt.
  modifier onlyCounekt {
    require(msg.sender.address == 0x49a71890aea5A751E30e740C504f2E9683f347bC);
  }

  /// @notice Modifier requiring a given version to be valid.
  /// @oaram versionName The name of the given version to check for.
  modifier onlyValidVersion(string versionName) {
    require(versionIsValid(versionName),"Version '"+versionName+"' isn't valid!");
  }
  
  /// @notice Checks if a given Administrable version is stored in the registry of valid versions.
  /// @param versionName The version name of the Administrable version to be checked for.
  function versionIsValid(string versionName) public view returns(bool){
    return validVersions[versionName]>0;
  }

  /// @notice Creates and returns a new Administrable entity.
  /// @param versionName The version name of the Administrable version to be created.
  /// @param idea The Idea that the Administrable will be attached to.
  function buildVersion(string versionName, address idea, address _creator) external returns(address) onlyValidVersion(versionName) {
    newVersionInstance = Administrable(versionByName[versionName]).create(idea, _creator);
    return newVersionInstance;
  }
  
  /// @notice Adds a new version of an Administrable entity to the registry of valid versions.
  /// @param versionName The version name of the Administrable version to be added.
  /// @param version The address of the new Administrable version to be added.
  function addVersion(string versionName, address version) external onlyCounekt {
    versionByName[versionName] = version;
    validVersions[versionName] = true;
    emit newVersion(versionName,version);
  }
  
  /// @notice Removes an Administrable version from the registry of valid versions.
  /// @param versionName The version name of the Administrable version to be removed.
  function removeVersion(string versionName) external onlyCounekt {
    validVersions[versionName] = false;
    emit depricatedVersion(versionName,versionByName[versionName]);
  }
}

