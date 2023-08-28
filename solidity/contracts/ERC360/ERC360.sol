// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC360} from "contracts/ERC360/IERC360.sol";
import {IERC360Metadata} from "contracts/ERC360/IERC360Metadata.sol";
import {IERC360Errors} from "contracts/ERC360/IERC360Errors.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/// @title A semi-fungible token that represents time-based fractional ownership.
/// @author Frederik W. L. Christoffersen
abstract contract ERC360 is Context, ERC165, IERC360, IERC360Metadata, IERC360Errors {
    using Counters for Counters.Counter;

    /// @notice Integer value to implement a concept of time and to distinguish tokens by id's.
    Counters.Counter _tokenIdClock;

    /// @notice A struct representing the related info of a semi-fungible Shard token.
    /// @param amount Amount that the token represents.
    /// @param owner The owner of the token.
    struct TokenInfo {
        uint256 amount;
        address owner; 
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /// @notice Mapping pointing to integer value representing the total amount of tokens on the market, provided the clock.
    mapping(uint256 => uint256) private _totalSupplyByClock;
    
    /// @notice Mapping pointing to a currently valid tokenId given the address of its owner.
    mapping(address => uint256) private _currentTokenIdByOwner;
    
    /// @notice Mapping pointing to related info of a token given the tokenId.
    mapping(uint256 => TokenInfo) private _infoByTokenId;

    // @notice Mapping pointing to an expiration clock given a tokenId.
    mapping(uint256 => uint256) private _expirationByTokenId;

    mapping(address => mapping(address => uint256)) private _allowances;


    /// @notice Event emitted when a new token is minted.
    /// @param owner The owner of the new token.
    /// @param tokenId The id of the token.
    event NewTokenId(
        address owner,
        uint256 tokenId
        );

    error ERC360InvalidTokenId(uint256, uint256);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC360).interfaceId ||
            interfaceId == type(IERC360Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC360-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _infoByTokenId[tokenId].owner;
    }

    function amountOf(uint256 tokenId) public view virtual returns (uint256) {
        return _infoByTokenId[tokenId].amount;
    }

    function tokenIdOf(address account) public view virtual returns (uint256) {
        return _currentTokenIdByOwner[account]; // if 0, account has never been owner of this token before
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return amountOf(tokenIdOf(account));
    }

    /// @notice Returns the clock.
    function currentClock() public view returns(uint256) {
        return _tokenIdClock.current();
    }

    /// @notice Returns the clock, in which a shard will or has expired.
    function expirationOf(uint256 tokenId) public view returns(uint256) {
        return _expirationByTokenId[tokenId] || type(uint256).max;
    }

    /// @notice Returns the supply at.
    function totalSupplyAt(uint256 clock) public view returns(uint256) {
        return _totalSupplyByClock[clock];
    }

    /// @notice Returns the current supply.
    function totalSupply() public view returns(uint256) {
        return totalSupplyAt(currentClock());
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param tokenId The shard, whose validity is to be checked for.
    function isValid(uint256 tokenId) public view returns(bool) {
        return currentClock() < expirationOf(tokenId);
    }
    
    /// @notice Returns a boolean stating if the given tokenId was current at a given clock.
    /// @param tokenId The token whose validity is to be checked for.
    /// @param clock The token clock to be checked for.
    function wasValid(uint256 tokenId, uint256 clock) public view returns(bool) {
        return tokenId <= clock && clock < expirationOf(tokenId);
    }

    /// @notice Approves the allowance of a certain amount of the sender to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function approve(address spender, uint256 amount) external virtual returns(bool) {
        _approve(spender,amount);
        emit Approval(_msgSender(), spender, amount);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(from,spender);
        if (currentAllowance < amount) {revert ERC360InsufficientAllowance(spender, currentAllowance, amount);}
        unchecked {_approve(from, spender, currentAllowance - amount, false);}
        _transfer(from, to, amount);
        return true;
    }

    
    /// @notice Approves the allowance of a certain amount of the sender to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function _approve(address spender, uint256 amount) internal virtual returns(bool) {
        require(balanceOf(_msgSender()) >= amount);
        _allowances[_msgSender()][spender] = amount;
        return true;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param shardId The shard to be split.
    /// @param amount Amount, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _transfer(address from, address to, uint256 amount) internal {
        require(amount <= balanceOf(from), "IA");
        // The amounts are added and the tokens thereby updated
        _update(from,balanceOf(from) - amount);
        _update(to,balanceOf(to) + amount);
    }
   
    function _mint(address account, uint256 amount) internal {
        _update(_msgSender(),amount);
        _totalSupplyByClock[currentClock()] += amount;
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param owner The owner of the Shard.
    /// @param amount Amount of the Shard represents.
    function _update(address account,uint256 amount) internal {
        if (account == address(0)) {revert ERC360InvalidReceiver(address(0));}
        _totalSupplyByClock[currentClock()+1] = _totalSupplyByClock[currentClock()]; // forward the total supply to next clock/tokenId
        _tokenIdClock.increment(); // increment clock/tokenId
        _expirationByTokenId[tokenIdOf(account)] = currentClock(); // Expire the old token
        _currentTokenIdByOwner[account] = currentClock();
        // The static info, amount and owner
        _infoByTokenId[currentClock()] = TokenInfo({
                                amount:amount,
                                owner: account});
        emit NewTokenId(account,currentClock());
    }

    function _requireValidAt(uint256 tokenId, uint256 clock) internal view {
        if (!wasValid(tokenId,clock)) {revert ERC360InvalidTokenId(tokenId,clock);}
    }

}
