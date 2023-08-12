// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Administrable} from "Administrable.sol";

/**
 * @dev Contract with spendable access-specified encapsulated funds via Administrable.
 *
 * Useful for scenarios such as preventing fraud and
 * making sure that spenders won't have access to all funds at once, 
 * which is fx. specifically appreciated within a corporation.
 *
 * IMPORTANT: This contract does not include external {Spendable-moveFunds} and {Spendable-transferFundsFromBank} functions.
 * In addition to inheriting this contract, you must define these functions, invoking the
 * {Spendable-_moveFunds} and {Spendable-_transferFundsFromBank} internal functions, with appropriate
 * access control. Not doing so will
 * make the contract mechanism unreachable, and thus unusable.
 */
abstract contract Spendable is Administrable {

    /// @notice A mapping pointing to the a value/amount of a stored token of a Bank, given the name of it and the respective token address.
    mapping(bytes32 => mapping(address => uint256)) private _balanceByBank;

    function bankBalanceOf(bytes32 bank, address tokenAddress) public view returns(uint256) {
        return balanceByBank[bank][tokenAddress];
    }

    /// @notice Internally moves funds from one Bank to another.
    /// @param fromBank The Bank from which the funds are to be moved.
    /// @param toBankName The Bank to which the funds are to be moved.
    /// @param tokenAddress The address of the token to be moved - address(0) if ether
    /// @param amount The value/amount of the funds to be moved.
    function _moveFunds(bytes32 fromBank, bytes32 toBank, address tokenAddress, uint256 amount) internal {
        require(amount <= balanceByBank[fromBank][tokenAddress]);
        unchecked {
            balanceByBank[fromBank][tokenAddress] -= amount;
            balanceByBank[toBank][tokenAddress] += amount;
        }
    }

    /// @notice Transfers a token bankAdmin a Bank to a recipient.
    /// @param bank The Bank from which the funds are to be transferred.
    /// @param tokenAddress The address of the token to be transferred - address(0) if ether
    /// @param value The value/amount of the funds to be transferred.
    /// @param to The recipient of the funds to be transferred.
    function _transferFundsFromBank(bytes32 bank, address to, address tokenAddress, uint256 amount) internal {
        require(amount <= balanceByBank[bank][tokenAddress]);
        unchecked {balanceByBank[bank][tokenAddress] -= amount;}
        _transferFunds(to,tokenAddress,amount);
    }

}