// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./shardable.sol";

/// @title A proof of fractional ownership of an entity with valuables.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
abstract contract Idea is Shardable {

    /// @notice Mapping pointing to boolean stating if a given token address is valid and registered or not.
    mapping(address => bool) validTokenAddresses;

	/// @notice Mapping pointing to a value/amount given the address of an ERC20 token.
    mapping(address => uint256) public liquid;

    /// @notice Integer block.timestamp of liquidization.
    uint256 liquidized_at;

    /// @notice Mapping pointing to the value/amount of a liquid token left to be claimed after liquidization/inactivation of the Idea.
    mapping(address => uint256) liquidResidual;

    /// @notice Mapping pointing to another mapping (given a token address) pointing to a boolean stating if the owner of a given Shard has claimed their fair share following a liquidization.
    mapping(address => mapping(bytes32 => bool)) hasClaimedLiquid;

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    /// @param amount Amount of shards to construct Shardable with.
    constructor(uint256 amount) Shardable(amount) {}

    /// @notice Returns the residual of a liquid, after liquidization/inactivation.
    /// @param tokenAddress The address of the token to be checked for.
    function getLiquidResidual(address tokenAddress) public view returns(uint256) {
        return liquidResidual[tokenAddress];
    }
    
    /// @notice Returns a boolean value, stating if the given token address is registered as acceptable or not.
    /// @param tokenAddress The address of the token to be checked for.
    function acceptsToken(address tokenAddress) public view returns(bool) {
      return validTokenAddresses[tokenAddress] == true || tokenAddress == address(0);
    }

    /// @notice Returns a boolean value, stating if the liquidization is terminated (100 days have passed since).
    function isTerminated() public view returns(bool) {
        return active == false && (block.timestamp-liquidized_at >= 300); //8640000
    }

    /// @notice Issues new shards and puts them for sale.
    /// @param tokenAddress The token address the shards are put for sale for.
    /// @param price The price per token.
    /// @param to The specifically set buyer of the issued shards. Open to anyone, if address(0).
    function _issueShards(uint256 amount, address tokenAddress, uint256 price, address to) virtual internal {
        require(acceptsToken(tokenAddress));
        _expireShard(shardByOwner[address(this)],clock);
        _pushShard(amount+infoByShard[shardByOwner[address(this)]].amount,address(this),clock);
        _putForSale(shardByOwner[address(this)],amount,tokenAddress,price,to);
    }

    /// @notice Transfers a token from the Idea to a recipient without processing the transfer.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) {_transferEther(value,to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "NA");
            require(token.transfer(to,value), "NT");
        }
    }

    /// @notice Transfers ether from the Idea to a recipient
    /// @param value The value/amount of ether to be transferred.
    /// @param to The recipient of the ether to be transferred.
    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call{value:value}("");
        require(success, "TF");
    }

    /// @notice Adds a token address to the registry. Also approves any future receipts of said token unless removed again.
    /// @param tokenAddress The token address to be registered.
    function _registerTokenAddress(address tokenAddress) virtual internal {
        require(!acceptsToken(tokenAddress), "AR");
        validTokenAddresses[tokenAddress] = true;
    }

    /// @notice Removes a token address from the registry. Also cancels any future receipts of said token unless added again.
    /// @param tokenAddress The token address to be unregistered.
    function _unregisterTokenAddress(address tokenAddress) virtual internal {
        require(acceptsToken(tokenAddress), "UT");
        require(liquid[tokenAddress] == 0, "NZ");
        validTokenAddresses[tokenAddress] = false;
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    function _liquidize() virtual internal onlyIfActive {
        active = false; // stops trading of Shards
        liquidized_at = block.timestamp;
    }

}
