// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Administrable} from "Administrable.sol";
import {ERC20Holder} from "ERC20Holder.sol";

/**
 * @dev Contract with spendable access-controlled encapsulated funds via Administrable.
 *
 * Useful for scenarios such as preventing fraud and
 * making sure that spenders won't have access to all funds at once, 
 * which is fx. specifically appreciated within a corporation.
 *
 * NOTE: For setting access, see {Administrable-_setPermit}.
 */
abstract contract Spendable is ERC20Holder, Administrable {

    /**
     *
     * @dev The balance of the master bank `bytes32(0)` returns the total amount reserved for all the other banks.
     * To calculate the actual balance of this bank,
     * this number is subtracted from the whole contract's balance of the given token.
     * In this way, the contract does NOT need to keep track of incoming tokens to work properly!
     */
    mapping(bytes32 => mapping(address => uint256)) private _balanceByBank;

    function balanceOfToken(address tokenAddress) public view returns(uint256) {
        if (tokenAddress == address(0)) {return address(this).balance;}
        else {return tokenAddress.balanceOf(address(this));}
    }

    function bankBalanceOf(bytes32 bank, address tokenAddress) public view returns(uint256) {
        if (bank == bytes32(0)) {return balanceOfToken(tokenAddress)-_balanceByBank[bank][tokenAddress];}
        else {return _balanceByBank[bank][tokenAddress];}
    }

    function moveFunds(bytes32 fromBank, bytes32 toBank, address tokenAddress, uint256 amount) external hasPermit(fromBank) {
        _moveFunds(fromBank,toBank,tokenAddress,amount);
    }

    function transferFundsFromBank(bytes32 bank, address tokenAddress, uint256 amount) external hasPermit(bank) {
        _transferFundsFromBank(bank,toBank,tokenAddress,amount);
    }

    /// @notice Internally moves funds from one Bank to another.
    /// @param fromBank The Bank from which the funds are to be moved.
    /// @param toBankName The Bank to which the funds are to be moved.
    /// @param tokenAddress The address of the token to be moved - address(0) if ether
    /// @param amount The value/amount of the funds to be moved.
    function _moveFunds(bytes32 fromBank, bytes32 toBank, address tokenAddress, uint256 amount) internal {
        require(amount <= bankBalanceOf(fromBank,tokenAddress));
        if (fromBank == bytes32(0)) {_balanceByBank[fromBank][tokenAddress] += amount;}
        else {
            _balanceByBank[fromBank][tokenAddress] -= amount;
        }
        if (toBank == bytes32(0)) {_balanceByBank[toBank][tokenAddress] -= amount;}
        else {_balanceByBank[toBank][tokenAddress] += amount;}  
        }
        
    }

    /// @notice Transfers a token bankAdmin a Bank to a recipient.
    /// @param bank The Bank from which the funds are to be transferred.
    /// @param tokenAddress The address of the token to be transferred - address(0) if ether
    /// @param value The value/amount of the funds to be transferred.
    /// @param to The recipient of the funds to be transferred.
    function _transferFundsFromBank(bytes32 bank, address to, address tokenAddress, uint256 amount) internal {
        require(amount <= bankBalanceOf(fromBank,tokenAddress));
        if (bank != bytes32(0)) {
            unchecked {
                _balanceByBank[bank][tokenAddress] -= amount;
                _balanceByBank[bytes32(0)][tokenAddress] -= amount;
            }
        }    
        _transferFunds(to,tokenAddress,amount);
    }

    function _transferFunds(address to, address tokenAddress, uint256 amount) {
        if (tokenAddress == address(0)) {
        (bool success, ) = address(to).call{value:value}("");
        require(success);
        }
        else {_transferToken(to,tokenAddress,amount);}
    }

}