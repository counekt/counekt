pragma solidity ^0.8.4;

import "./shardable.sol";

/// @title A proof of fractional ownership of an entity with valuables.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

    /// @notice A struct representing a registration of an owned ERC20 token and its value/amount.
    /// @param value The value/amount of the token.
    /// @param originalValue The value/amount of the token before liquidization/inactivation of the Idea.
    struct TokenRegister {
        uint256 value;
        uint256 originalValue;
    }

    /// @notice Mapping pointing to boolean stating if a given token address is valid and registered or not.
    mapping(address => bool) validTokenAddresses;

	/// @notice Mapping pointing to a Token Register given the address of the ERC20 token contract.
    mapping(address => TokenRegister) liquid;

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

    /// @notice Event that triggers when a token is transferred.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    /// @param to The recipient of the transferred token.
    event TokenTransferred(
        address tokenAddress,
        uint256 value,
        address to
    );

    /// @notice Event that triggers when the entity is liquidized. Can only be emitted once during the lifetime of an entity.
    /// @param by The initiator of the liquidization.
    event EntityLiquidized(address by);

    /// @notice Event that triggers when part of the liquid is claimed following a liquidization.
    /// @param tokenAddress The address of the claimed token.
    /// @param value The value/amount of the claimed token.
    event LiquidClaimed(
        address tokenAddress,
        uint256 value,
        address by
    );

    /// @notice Receive function that receives ether when there's no supplying data
    receive() external payable onlyIfActive {
        require(active == true, "EL");
        _processTokenReceipt(address(0),msg.value,msg.sender);
    }

    /// @notice Receives a specified token and adds it to the registry. Make sure 'token.approve()' is called beforehand.
    /// @param tokenAddress The address of the token to be received.
    /// @param value The value/amount of the token to be received.
    function receiveToken(address tokenAddress, uint256 value) external {
        require(acceptsToken(tokenAddress));
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "NAT");
        _processTokenReceipt(tokenAddress,value,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction after the entity has been liquidized/dissolved.
    /// @param tokenAddress The address of the token to be claimed.
    function claimLiquid(address tokenAddress) external onlyShardHolder onlyIfActive {
        require(acceptsToken(tokenAddress), "PANT");
        require(!hasClaimedLiquid[tokenAddress][shardByOwner[msg.sender]], "AC");
        hasClaimedLiquid[tokenAddress][shardByOwner[msg.sender]] = true;
        uint256 liquidValue = infoByShard[shardByOwner[msg.sender]].numerator / infoByShard[shardByOwner[msg.sender]].denominator * liquid[tokenAddress].originalValue;
        liquid[tokenAddress].value -= liquidValue;
        _transferToken(tokenAddress,liquidValue,msg.sender);
        emit LiquidClaimed(tokenAddress,liquidValue,msg.sender);
    }

    /// @notice Returns true. Used for differentiating between Idea and non-Idea contracts.
    function isIdea() public pure returns(bool) {
        return true;
    }
    
    /// @notice Returns a boolean value, stating if the given token address is registered as acceptable or not.
    /// @param tokenAddress The address of the token to be checked for.
    function acceptsToken(address tokenAddress) public view returns(bool) {
      return validTokenAddresses[tokenAddress] == true;
    }

    /// @notice Transfers a token from the Idea to a recipient. 
    /// @dev First 'token.approve()' is called, then 'to.receiveToken()', if it's an Idea.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) { _transferEther(value, to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "NA");
            if (Idea(payable(to)).isIdea()) {
                Idea(payable(to)).receiveToken(tokenAddress, value);
            }
        }
        _processTokenTransfer(tokenAddress,value,to);
    }

    /// @notice Transfers ether from the Idea to a recipient
    /// @param value The value/amount of ether to be transferred.
    /// @param to The recipient of the ether to be transferred.
    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call{value:value}("");
        require(success, "TF");
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    /// @param by The initiator of the liquidization.
    function _liquidize(address by) internal {
        active = false; // stops trading of Shards
        emit EntityLiquidized(by);
    }

    /// @notice Processes a token receipt and adds it to the token registry.
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) virtual internal {
        liquid[tokenAddress].originalValue += value;
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Processes a token transfer and subtracts it from the token registry.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    /// @param to The recipient of the transferred token.
    function _processTokenTransfer(address tokenAddress, uint256 value, address to) virtual internal {
        liquid[tokenAddress].originalValue -= value;
        emit TokenTransferred(tokenAddress,value,to);
    }

    /// @notice Adds a token address to the registry. Also approves any future receipts of said token unless removed again.
    /// @param tokenAddress The token address to be registered.
    function _registerTokenAddress(address tokenAddress) internal {
        require(!acceptsToken(tokenAddress), "AR");
        validTokenAddresses[tokenAddress] = true;
        // Update liquidization
        liquid[tokenAddress] = TokenRegister({value:0,originalValue:0});
    }

    /// @notice Removes a token address from the registry. Also cancels any future receipts of said token unless added again.
    /// @param tokenAddress The token address to be unregistered.
    function _unregisterTokenAddress(address tokenAddress) internal {
        require(acceptsToken(tokenAddress), "TNR");
        require(liquid[tokenAddress].originalValue == 0, "NZ");
        validTokenAddresses[tokenAddress] = false;
    }

}
