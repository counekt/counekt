// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./shardable.sol";

interface IIdea {

    function receiveToken(address,uint256) external;
}

/// @title A proof of fractional ownership of an entity with valuables.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

    /// @notice Mapping pointing to boolean stating if a given token address is valid and registered or not.
    mapping(address => bool) validTokenAddresses;

	/// @notice Mapping pointing to a value/amount given the address of an ERC20 token.
    mapping(address => uint256) public liquid;

    /// @notice Mapping pointing to the value/amount of a liquid token left to be claimed after liquidization/inactivation of the Idea.
    mapping(address => uint256) liquidResidual;

    /// @notice Mapping pointing to another mapping (given a token address) pointing to a boolean stating if the owner of a given Shard has claimed their fair share following a liquidization.
    mapping(address => mapping(bytes32 => bool)) hasClaimedLiquid;

    /// @notice Event that triggers when a token is received.
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    event TokenReceived(
        address tokenAddress,
        uint256 value,
        address from
    );

    /// @notice Event that triggers when part of the liquid is claimed following a liquidization.
    /// @param tokenAddress The address of the claimed token.
    /// @param value The value/amount of the claimed token.
    event LiquidClaimed(
        address tokenAddress,
        uint256 value,
        address by
    );

    /// @notice Receive function that receives ether when there's no supplying data
    receive() external payable {
        _processTokenReceipt(address(0),msg.value,msg.sender);
    }

    /// @notice Receives a specified token and adds it to the registry. Make sure 'token.approve()' is called beforehand.
    /// @param tokenAddress The address of the token to be received.
    /// @param value The value/amount of the token to be received.
    function receiveToken(address tokenAddress, uint256 value) external {
        require(acceptsToken(tokenAddress),"UT");
        ERC20 token = ERC20(tokenAddress);
        require(token.allowance(msg.sender,address(this)) >= value,"IT");
        require(token.transferFrom(msg.sender,address(this), value), "NT");
        _processTokenReceipt(tokenAddress,value,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction after the entity has been liquidized/dissolved.
    /// @param tokenAddress The address of the token to be claimed.
    function claimLiquid(address tokenAddress) external onlyShardHolder {
        require(acceptsToken(tokenAddress), "UT");
        bytes32 shard = shardByOwner[msg.sender];
        require(!hasClaimedLiquid[tokenAddress][shard], "AC");
        hasClaimedLiquid[tokenAddress][shard] = true;
        uint256 liquidValue = liquid[tokenAddress] * infoByShard[shard].amount / totalShardAmountByClock[clock];
        require(liquidValue != 0, "");
        liquidResidual[tokenAddress] -= liquidValue;
        _transferToken(tokenAddress,liquidValue,msg.sender);
        emit LiquidClaimed(tokenAddress,liquidValue,msg.sender);
    }

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

    /// @notice Transfers a token from the Idea to a recipient. 
    /// @dev First 'token.approve()' is called, then 'to.receiveToken()', if it's an Idea.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        require(liquid[tokenAddress] >= value, "IT");
        if (tokenAddress == address(0)) { _transferEther(value, to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "NA");
            if (to.code.length > 0) {
                try IIdea(to).receiveToken(tokenAddress, value) {
                    // do nothing
                }
                catch {// do nothing but skip the exception}
                }
            }
            else {
              require(token.transfer(to,value), "NT");
            }
        }
        if (active) {_processTokenTransfer(tokenAddress,value);}
        
    }

    /// @notice Transfers ether from the Idea to a recipient
    /// @param value The value/amount of ether to be transferred.
    /// @param to The recipient of the ether to be transferred.
    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call{value:value}("");
        require(success, "TF");
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    function _liquidize() virtual internal onlyIfActive {
        active = false; // stops trading of Shards
    }

    /// @notice Processes a token receipt and adds it to the token registry.
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) virtual internal {
        liquid[tokenAddress] += value;
        liquidResidual[tokenAddress] += value;
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Processes a token transfer and subtracts it from the token registry.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    function _processTokenTransfer(address tokenAddress, uint256 value) virtual internal {
        liquid[tokenAddress] -= value;
        liquidResidual[tokenAddress] -= value;
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

}
