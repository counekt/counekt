pragma solidity ^0.8.20;

import {Context} from "node_modules/@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC360} from "./IERC360.sol";
import {IERC360Metadata} from "./IERC360Metadata.sol";
import {IERC360Errors} from "./IERC360Errors.sol";
import {Counters} from "node_modules/@openzeppelin/contracts/utils/Counters.sol";

/// @title A semi-fungible token that represents time-based fractional ownership.
/// @author Frederik W. L. Christoffersen
abstract contract ERC360 is Context, ERC165, IERC360, IERC360Metadata, IERC360Errors {
    using Counters for Counters.Counter;

    /// @notice Integer value to implement a concept of time and to distinguish tokens by id's.
    Counters.Counter _shardClock;

    /// @notice A struct representing the related info of the semi-fungible shard of the ERC360 token.
    /// @param amount Amount that the token represents.
    /// @param owner The owner of the token.
    struct ShardInfo {
        uint256 amount;
        address owner; 
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /// @notice Mapping pointing to integer value representing the total amount of tokens on the market, provided the clock.
    mapping(uint256 => uint256) private _totalSupplyByClock;
    
    /// @notice Mapping pointing to a currently valid shardId given the address of its owner.
    mapping(address => uint256) private _currentShardIdByOwner;
    
    /// @notice Mapping pointing to related info of a token given the shardId.
    mapping(uint256 => ShardInfo) private _infoByShardId;

    // @notice Mapping pointing to an expiration clock given a shardId.
    mapping(uint256 => uint256) private _expirationByShardId;

    mapping(address => mapping(address => uint256)) private _allowances;

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
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {return _name;}

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory) {return _symbol;}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
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

    function ownerOf(uint256 shardId) public view virtual returns (address) {
        return _infoByShardId[shardId].owner;
    }

    function amountOf(uint256 shardId) public view virtual returns (uint256) {
        return _infoByShardId[shardId].amount;
    }

    function shardIdOf(address account) public view virtual returns (uint256) {
        return _currentShardIdByOwner[account]; // if 0, account has never been owner of this token before
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return amountOf(shardIdOf(account));
    }

    /// @notice Returns the clock.
    function currentClock() public view returns(uint256) {
        return _shardClock.current();
    }

    /// @notice Returns the clock, in which a shard will or has expired.
    function expirationOf(uint256 shardId) public view returns(uint256) {
        return  _expirationByShardId[shardId] > 0 ? _expirationByShardId[shardId] : type(uint256).max;
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
    /// @param shardId The shard, whose validity is to be checked for.
    function isValid(uint256 shardId) public view returns(bool) {
        return currentClock() < expirationOf(shardId);
    }
    
    /// @notice Returns a boolean stating if the given shard was current at a given clock.
    /// @param shardId The token whose validity is to be checked for.
    /// @param clock The token clock to be checked for.
    function wasValid(uint256 shardId, uint256 clock) public view returns(bool) {
        return shardId <= clock && clock < expirationOf(shardId);
    }

    /// @notice Approves the allowance of a certain amount of the sender to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function approve(address spender, uint256 amount) external virtual returns(bool) {
        _approve(_msgSender(),spender,amount);
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
        unchecked {_approve(from, spender, currentAllowance - amount);}
        _transfer(from, to, amount);
        return true;
    }

    
    /// @notice Approves the allowance of a certain amount of the sender to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function _approve(address from, address spender, uint256 amount) internal virtual returns(bool) {
        require(balanceOf(from) >= amount);
        _allowances[from][spender] = amount;
        return true;
    }

    /// @notice Transfers a token 'amount' 'from' an address 'to' another.
    /// @param from, The sender of the tokens.
    /// @param amount The amount, which is transferred.
    /// @param to The recipient of the transfer.
    function _transfer(address from, address to, uint256 amount) internal {
        require(amount <= balanceOf(from), "IA");
        // The amounts are added and the tokens thereby updated
        _update(from,balanceOf(from) - amount);
        _update(to,balanceOf(to) + amount);
    }
   
    /// @notice Mints a specific 'amount' of new tokens at an 'account'
    /// @param account The recipient of the newly minted tokens.
    /// @param amount Amount, which will be subtracted from the previous shard and sent to the receiver.
    function _mint(address account, uint256 amount) internal {
        _update(account,amount+balanceOf(account)); // dev: increments clock
        _totalSupplyByClock[currentClock()] += amount; // Update now new total supply
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param account The owner of the Shard.
    /// @param amount Amount that the Shard represents.
    function _update(address account,uint256 amount) internal {
        if (account == address(0)) {revert ERC360InvalidReceiver(address(0));}
        _totalSupplyByClock[currentClock()+1] = _totalSupplyByClock[currentClock()]; // forward the old total supply to next shard clock
        _shardClock.increment(); // increment shard clock
        _expirationByShardId[shardIdOf(account)] = currentClock(); // Expire the old token
        _currentShardIdByOwner[account] = currentClock();
        // Create new shard with static info; amount and owner
        _infoByShardId[currentClock()] = ShardInfo({
                                amount:amount,
                                owner: account});
        emit NewShard(account,currentClock());
    }

    function _requireValidAt(uint256 shardId, uint256 clock) internal view {
        if (!wasValid(shardId,clock)) {revert ERC360InvalidShard(shardId,clock);}
    }

}
