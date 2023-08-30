// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Administrable} from "contracts/ERC360/utils/Administrable.sol";
import {ERC20Holder} from "contracts/ERC360/utils/ERC20Holder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


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

    function balanceOfToken(address token) public view returns(uint256) {
        if (token == address(0)) {return address(this).balance;}
        else {return IERC20(token).balanceOf(address(this));}
    }

    function bankBalanceOf(bytes32 bank, address token) public view returns(uint256) {
        if (bank == bytes32(0)) {return balanceOfToken(token)-_balanceByBank[bank][token];}
        else {return _balanceByBank[bank][token];}
    }

    function moveFunds(bytes32 fromBank, bytes32 toBank, address token, uint256 amount) external onlyPermit(fromBank) {
        _moveFunds(fromBank,toBank,token,amount);
    }

    function transferFundsFromBank(bytes32 bank, address to, address token, uint256 amount) external onlyPermit(bank) {
        _transferFundsFromBank(bank,to,token,amount);
    }

    /// @notice Internally moves funds from one Bank to another.
    /// @param fromBank The Bank from which the funds are to be moved.
    /// @param toBank The Bank to which the funds are to be moved.
    /// @param token The address of the token to be moved - address(0) if ether
    /// @param amount The value/amount of the funds to be moved.
    function _moveFunds(bytes32 fromBank, bytes32 toBank, address token, uint256 amount) internal {
        require(amount <= bankBalanceOf(fromBank,token));
        if (fromBank == bytes32(0)) {_balanceByBank[fromBank][token] += amount;}
        else {_balanceByBank[fromBank][token] -= amount;}
        if (toBank == bytes32(0)) {_balanceByBank[toBank][token] -= amount;}
        else {_balanceByBank[toBank][token] += amount;}  
    }

    /// @notice Transfers a token bankAdmin a Bank to a recipient.
    /// @param bank The Bank from which the funds are to be transferred.
    /// @param token The address of the token to be transferred - address(0) if ether
    /// @param amount The value/amount of the funds to be transferred.
    /// @param to The recipient of the funds to be transferred.
    function _transferFundsFromBank(bytes32 bank, address to, address token, uint256 amount) internal {
        _registerTransferFromBank(bank,token,amount);
        _transferFunds(to,token,amount);
    }

    function _registerTransferFromBank(bytes32 bank,address token, uint256 amount) internal {
        require(amount <= bankBalanceOf(bank,token));
        if (bank != bytes32(0)) {
            unchecked {
                _balanceByBank[bank][token] -= amount;
                _balanceByBank[bytes32(0)][token] -= amount;
            }
        }    
    }

}