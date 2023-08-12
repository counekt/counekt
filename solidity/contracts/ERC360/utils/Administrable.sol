pragma solidity ^0.8.20;

import {Context} from "../../@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module that allows decendants to implement permit-based access
 * control mechanisms. (Inspired by AccessControl).
 *
 * Permits are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_PERMIT = keccak256("MY_PERMIT");
 * ```
 *
 * Permits can be used to represent permission. To restrict access to a
 * function call, use {hasPermit}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasPermit(MY_PERMIT, msg.sender));
 *     ...
 * }
 * ```
 *
 * Permits can be set dynamically via the {setPermit} function. Each permit has an associated parent, and only
 * accounts that have a permits's parent permit can call {setPermit}.
 *
 * By default, the parent permit for all permits is `bytes32(0)`, which means
 * that by default only accounts with this permit will be able to set other
 * permits. More complex permit relationships can be created by using
 * {_setPermitParent}.
 *
 * INFO: The `bytes32(0)` permit is also its own parent: it has permission to
 * set this permit. Permits whose holders also hold its parents can't be revoked externally.
 * This means that the parent of a permit must be revoked before revoking the child.
 * The master permit `bytes32(0)` can therefore NOT be externally revoked either.
 */
abstract contract Administrable is Context {

    /// @notice A mapping pointing to another mapping, pointing to a Permit State, given the address of a permit holder, given the name of the permit.
    /// @custom:illustration permits[permitName][address] == PermitState.authorized || PermitState.administrator;
    mapping(bytes32 => mapping(address => bool)) _hasPermit;
    mapping(bytes32 => bytes32) _parentByPermit;

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
        return _hasPermit[permit][account];
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given permit or not.
    /// @param permit The name of the permit to be checked for.
    /// @param account The address to be checked for.
    function isPermitAdmin(bytes32 permit, address account) public view returns(bool) {
        return hasPermit(permitParentOf(permit));
    }

    function permitParentOf(bytes32 permit) public view returns(bytes32) {
        return _parentByPermit[permit];
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param account The address, whose permit state is to be set.
    /// @param permit The name of the permit, whose state is to be set.
    /// @param newState The new Permit State to be applied.
    function setPermit(bytes32 permit, address account, bool status) external onlyPermitAdmin(permit) {
        if (status == false && isPermitAdmin(permit,account)) {revert AdministrableUnauthorizedSet(permit,account);}
        _setPermit(permit,account,status);
    }

    function setPermitParent(bytes32 permit, bytes32 parent) external onlyPermitAdmin(permit) {
        _setPermitParent(permit, parent);
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param permit The permit, whose state is to be set.
    /// @param account The address, whose permit state is to be set.
    /// @param newState The new Permit State to be applied.
    function _setPermit(bytes32 permit, address account, bool status) internal {
        if (_hasPermit[permit][account] != status) {
            _hasPermit[permit][account] = status;
        }
    }

    function _setPermitParent(bytes32 permit, bytes32 parent) internal {
        if (permit == bytes32(0)) {revert AdministrableInvalidParentSet(permit,parent);}
        _parentByPermit[permit] = parent;
    }

}