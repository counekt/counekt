// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./shardable.sol";
import "./erc20holder.sol";

/// @title A proof of fractional ownership of an entity with valuables.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:beaware This is a commercial contract.
abstract contract Idea is Shardable, ERC20Holder {

    /// @notice Boolean stating if the Shardable is active and tradeable or not.
    bool public active;

    /// @notice Mapping pointing to boolean stating if a given token address is valid and registered or not.
    mapping(address => bool) validTokenAddresses;

	/// @notice Mapping pointing to a value/amount given the address of an ERC20 token.
    mapping(address => uint256) public liquid;

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

    /// @notice Transfers funds (tokens or ether) to a recipient.
    /// @param to The recipient of the ether to be transferred.
    /// @param tokenAddress The address of the token to be transferred - is address(0) if ether
    /// @param amount The amount of funds to be transferred.
    function _transferFunds(address to, address tokenAddress, uint256 amount) {
        if (tokenAddress == address(0)) {_transferEther(to,amount)}
        else {_transferToken(to,tokenAddress,amount)}
    }

    /// @notice Transfers ether to a recipient
    /// @param amount The value of ether to be transferred.
    /// @param to The recipient of the ether to be transferred.
    function _transferEther(address to,uint256 value) internal {
        (bool success, ) = address(to).call{value:value}("");
        require(success, "TF");
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    function _liquidize() virtual internal onlyIfActive {
        active = false; // stops trading of Shards
        liquidized_at = block.timestamp;
    }

}
