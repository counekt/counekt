pragma solidity ^0.8.20;

import {Context} from "../../@openzeppelin/contracts/utils/Context.sol";

abstract contract Administrable is Context {

    /// @notice An enum representing a Permit State of one of the many permits.
    /// @param unauthorized The permit is NOT authorized.
    /// @param authorized The permit is authorized.
    /// @param administrator The holder of the permit is not only authorized but also an administrator of it too.
    enum PermitState {
        unauthorized,
        authorized,
        administrator
    }

    /// @notice A mapping pointing to another mapping, pointing to a Permit State, given the address of a permit holder, given the name of the permit.
    /// @custom:illustration permits[permitName][address] == PermitState.authorized || PermitState.administrator;
    mapping(bytes32 => mapping(address => bool)) permits;
    mapping(bytes32 => bytes32) permitAdmin;


    /// @notice Modifier that makes sure msg.sender has a given permit.
    /// @param permit The name of the permit to be checked for.
    modifier onlyWithPermit(bytes32 permit) {
        require(hasPermit(permit,_msgSender()));
        _;
    }
    
    /// @notice Modifier that makes sure msg.sender is an admin of a given permit.
    /// @param permit The name of the permit to be checked for.
    modifier onlyPermitAdmin(bytes32 permit) {
        require(isPermitAdmin(permit,_msgSender()));
        _;
    }

    /// @notice Returns a boolean stating if a given address has a given permit or not.
    /// @param permit The name of the permit to be checked for.
    /// @param account The address to be checked for.
    function hasPermit(bytes32 permit, address account) public view returns(bool) {
        return permits[permit][account] >= PermitState.authorized;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given permit or not.
    /// @param permit The name of the permit to be checked for.
    /// @param account The address to be checked for.
    function isPermitAdmin(bytes32 permit, address account) public view returns(bool) {
        return permits[permit][account] == PermitState.administrator;
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param account The address, whose permit state is to be set.
    /// @param permit The name of the permit, whose state is to be set.
    /// @param newState The new Permit State to be applied.
    function setPermit(bytes32 permit, address account, PermitState newState) external onlyPermitAdmin(permitName) {
        _setPermit(permit,account,newState);
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param permit The permit, whose state is to be set.
    /// @param account The address, whose permit state is to be set.
    /// @param newState The new Permit State to be applied.
    function _setPermit(bytes32 permit, address account, PermitState newState) internal {
        if (permits[permit][account] != newState) {
            permits[permit][account] = newState;
        }
    }

}