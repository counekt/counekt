pragma solidity ^0.8.4;

import "../versionControl.sol";
import "../shardable.sol";


/// @title A proof of fractional ownership of an entity with valuables (administered by Administerable).
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

    /// @notice A struct representing a registration of an owned ERC20 token and its value/amount.
    /// @param value The value/amount of the token.
    /// @param originalValue The value/amount of the token before liquidization/inactivation of the Idea.
    /// @param hasClaimed Mapping pointing to a boolean stating if the owner of a Shard has claimed their fair share following a liquidization.
    struct TokenRegister {
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) hasClaimed;
    }

	/// @notice The Administrable contract entity from which the Idea is administered.
	address administrable;

	/// @notice Mapping pointing to a Token Register given the address of the ERC20 token contract.
    mapping(address => TokenRegister) liquid;
    /// @notice Array storing all the registered token addresses.
    address[] tokenAddresses;
    /// @notice Mapping pointing to an index of the 'tokenAddresses' array, given a token address.
    mapping(address => uint256) tokenAddressIndex; // starts from 1 and up, to differentiate betweeen empty values

    /// @notice Modifier requiring the msg.sender to be the administrable entity.
    modifier onlyAdministrable {
    	require(msg.sender == administrable);
    }

    /// @notice Constructor function setting up the Administrable entity, given the name of the Administrable type.
    /// @param administrableType The type of Administrable to be set up.
    constructor(string administrableType) {
        // AdministrableVersioner = *whatever the address of it will be*
        _setAdministrable(AdministrableVersioner.buildVersion(administrableType, this.address, msg.sender.address));
    }

    /// @notice Receives ether when there's no supplying data
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processTokenReceipt(address(0),msg.value,msg.sender);
    }

    /// @notice Fallback function that forwards unregistered function calls to the Administrable entity.
    fallback() external {
      administrable.call(msg.data);
    }

    /// @notice Receives a specified token and adds it to the registry. Make sure 'token.approve()' is called beforehand.
    function receiveToken(address tokenAddress, uint256 value) external {
        require(acceptsToken(tokenAddress));
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(tokenAddress,value,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction after the entity has been liquidized/dissolved.
    /// @inheritdoc _liquidize
    function claimLiquid(address shardHolder, address tokenAddress) external onlyShardHolder {
        require(active == false, "Can't claim liquid, when the entity isn't dissolved and liquidized.");
        require(tokenAddressIndex[tokenAddress] > 0, "Liquid doesn't contain token with address '"+string(tokenAddress)+"'");
        Dividend tokenLiquid = liquid[tokenAddress];
        
        require(!tokenLiquid.hasClaimed[msg.sender], "Liquid token'"+string(tokenAddress)+"' already claimed!");
        tokenLiquid.hasClaimed[msg.sender] = true;
        liquidValue = shardByOwner[shardHolder].fraction.numerator / shardByOwner[msg.sender].fraction.denominator * tokenLiquid.originalValue;
        tokenLiquid.value -= liquidValue;
        if (tokenLiquid.value == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        _transferToken(tokenAddress,liquidValue,msg.sender);
        emit LiquidClaimed(liquidValue,msg.sender);
    }

    /// @inheritdoc _transferToken
    function transferToken_(address tokenAddress, uint256 value, address to) external onlyAdministrable {
        _transferToken(tokenAddress,value,to);
    }

    /// @inheritdoc _liquidize
    function liquidize_() external onlyAdministrable {
        _liquidize(by);
    }

    /// @inheritdoc _setAdministrable
    function setAdministrable_(address _administrable) external onlyAdministrable {
        _setAdministrable(_administrable);
    }
    
    /// @inheritdoc _registerTokenAddress
    function registerTokenAddress_(address tokenAddress) external onlyAdministrable {
      _registerTokenAddress(tokenAddress);
    }
    
    /// @inheritdoc _unregisterTokenAddress
    function unregisterTokenAddress_(address tokenAddress) external onlyAdministrable {
      _unregisterTokenAddress(tokenAddress);
    }

    /// @notice Returns true. Used for differentiating between Idea and non-Idea contracts.
    function isIdea() constant pure returns(bool) {
        return true;
    }
    
    /// @notice Returns a boolean value stating if the token address is registered as acceptable.
    function acceptsToken(address tokenAddress) public view {
      return tokenAddressIndex[tokenAddress]>0;
    }

    /// @notice Transfers a token from the Idea to a recipient. 
    /// First token.approve() is called, then to.receiveToken if it's an Idea.
    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) { _transferEther(value, to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "Failed to approve transfer");
            if (to.isIdea()) {
                Idea(to).receiveToken("main", tokenAddress, value);
            }
        }
        _processTokenTransfer(tokenAddress,value,to);
    }

    /// @notice Transfers ether from the Idea to a recipient
    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }


    // @notice Sets a new address of the Administrable, which controls all unknown function calls and the Idea itself.
    function _setAdministrable(address _administrable) internal {
        require(Administrable(_administrable).isAdministrable())
        administrable = _administrable;
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize() internal {
        active = false; // stops trading of Shards
        emit EntityLiquidized();
    }

    /// @notice Processes a token receipt and adds it to the token registry.
    /// @dev Calls an Administrable.processTokenReceipt, since it otherwise doesn't know about the Idea Receipt.
    /// @custom:illustration Idea.receiveToken() => Idea._processTokenReceipt() => Administrable.processTokenReceipt()
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) internal {
        // First: Liquid logic
        liquid[tokenAddress].originalValue += value;
        administrable.processTokenReceipt(tokenAddress, value, from);
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Processes a token transfer and subtracts it from the token registry.
    /// @dev Does NOT call an Administrable.processTokenTransfer, since transfer calls always stem from there.
    /// @custom:illustration Administrable.transferToken() => Idea.transferToken() + Administrable._processTokenTransfer() => Idea._processTokenTransfer()
    function _processTokenTransfer(address tokenAddress, uint256 value, address to) internal {
        // First: Liquidization logic
        liquid[tokenAddress].originalValue -= value;
        if (liquid[tokenAddress].originalValue == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        emit TokenTransfered(tokenAddress,value,to);
    }

    /// @notice Adds a token address to the registry. Also approves any future receipts of said token unless removed again.
    function _registerTokenAddress(address tokenAddress) {
        require(!acceptsToken(tokenAddress), "Token address '"+string(tokenAddress)+"' ALREADY registered!");
        tokenAddressIndex[tokenAddress] = tokenAddresses.length + 1; // +1 to distinguish between empty values;
        tokenAddresses.push(tokenAddress);
        // Update liquidization
        TokenRegister newTokenRegister = new TokenRegister();
        newTokenRegister.tokenAddress = tokenAddress;
        newTokenRegister.originalValue = 0;
        liquid[tokenAddress] = newTokenRegister;
    }

    /// @notice Removes a token address from the registry. Also cancels any future receipts of said token unless added again.
    function _unregisterTokenAddress(address tokenAddress) {
        require(acceptsToken(tokenAddress), "Token address '"+string(tokenAddress)+"' NOT registered!");
        require(liquid[tokenAddress].originalValue == 0, "Token amount must be 0 before unregistering!");

        tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1]; // -1 to distinguish between empty values;
        tokenAddressIndex[tokenAddress] = 0; // a stored index value of 0 means empty
        tokenAddress.pop();
    }

}
