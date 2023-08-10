// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;


/**
 * @dev Contract with access-specified spendable encapseled funds.
 *
 * Useful for scenarios such as preventing fraud and
 * making sure that spenders won't have access to all funds at once, 
 * which is specifically appreciated within a corporation.
 *
 * IMPORTANT: This contract does not include public setBankAccess, moveFunds and transferFundsFromBank functions.
 * In addition to inheriting this contract, you must define these functions, invoking the
 * {Spendable-_setBankAccess}, {Spendable-_moveFunds} and {Spendable-_transferFundsFromBank} internal functions, with appropriate
 * access control, e.g. using {Administrable} or {Ownable}. Not doing so will
 * make the contract mechanism unreachable, and thus unusable.
 */
abstract contract Spendable {

    /// @notice A mapping pointing to the a value/amount of a stored token of a Bank, given the name of it and the respective token address.
    mapping(uint256 => mapping(address => uint256)) private balanceByBank;

    /// @notice A mapping pointing to a boolean stating if an address is an if a given address is a valid Bank admin.
    mapping(uint256 => mapping(address => bool)) private accessToBank;

    function bankBalanceOf(uint256 bank, address tokenAddress) public view returns(uint256) {
        return balanceByBank[bank][tokenAddress];
    }

    function hasAccessToBank(uint256 bank,address account) public view returns(bool){
        return accessToBank[bank][account];
    }

    /// @notice Sets the admin status within a specific Bank of a given account.
    /// @param bank The name of the Bank from which the given account's admin status is to be set.
    /// @param admin The address of the account, whose admin status it to be set.
    /// @param status The admin status to be set.
    function _setBankAccess(uint256 bank, address admin, bool status) internal {
        adminOfBank[bank][admin] = status;
    }

    /// @notice Internally moves funds from one Bank to another.
    /// @param fromBank The Bank from which the funds are to be moved.
    /// @param toBankName The Bank to which the funds are to be moved.
    /// @param tokenAddress The address of the token to be moved - address(0) if ether
    /// @param amount The value/amount of the funds to be moved.
    function _moveFunds(uint256 fromBank, uint256 toBank, address tokenAddress, uint256 amount) internal {
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
    function _transferFundsFromBank(uint256 bank, address to, address tokenAddress, uint256 amount) internal {
        require(amount <= balanceByBank[bank][tokenAddress]);
        unchecked {balanceByBank[bank][tokenAddress] -= amount;}
        _transferFunds(to,tokenAddress,amount);
    }

}