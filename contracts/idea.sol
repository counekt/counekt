pragma solidity ^0.8.4;

import "../versionControl.sol";
import "../shardable.sol";


/// @title A proof of fractional ownership of an entity with valuables (administered by Administerable).
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

    struct TokenRegister {
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) hasClaimed; // Ín case of liquidization - Shard Holders claim their fair share of the value.
    }

	// Administration
	// this is the contract from which the Idea is administered.
	address administrable;

	// Liquidization keeps track of all tokens
    // is updated along the way
    mapping(address => TokenRegister) liquid;
    address[] tokenAddresses;
    mapping(address => uint256) tokenAddressIndex; // starts from 1 and up, to differentiate betweeen empty values

    modifier onlyAdministrable {
    	require(msg.sender == administrable);
    }

    constructor(string administrableType) {
        // AdministrableVersioner = *whatever the address of it will be*
        _setAdministrable(AdministrableVersioner.createVersion(administrableType, this.address));
    }

    /// @notice Receives ether when there's no supplying data
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processTokenReceipt(address(0),msg.value,msg.sender);
    }

    // when calling an unknown function, the Idea calls the Administrable
    // idea => administrable => idea
    fallback() external {
      administrable.call(msg.data);
    }

    /// @notice Receives a specified token and adds it to the registry
    /// First token.approve() should be called by msg.sender, then this function
    function receiveToken(address tokenAddress, uint256 value) external {
        require(acceptsToken(tokenAddress));
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(tokenAddress,value,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction when the entity has been liquidized/dissolved.
    /// @inheritdoc _liquidize
    /// @dev NOW UP TO DATE WITH THE TOKEN ECOSYSTEM IMPLEMENTATION
    function claimLiquid(address shardHolder, address tokenAddress) external onlyShardHolder {
        require(active == false, "Can't claim liquid, when the entity isn't dissolved and liquidized.");
        require(tokenAddressIndex[tokenAddress] > 0, "Liquid doesn't contain token with address '"+string(tokenAddress)+"'");
        Dividend tokenLiquid = liquid[tokenAddress];
        
        require(!tokenLiquid.hasClaimed[msg.sender], "Liquid token'"+string(tokenAddress)+"' already claimed!");
        tokenLiquid.hasClaimed[msg.sender] = true;
        liquidValue = getDecimal(shardByOwner[shardHolder].fraction) * tokenLiquid.originalValue;
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
    function isIdea() pure returns(bool) {
        return true;
    }
    
    /// @notice Returns a boolean value depending on if a token address is registered as an acceptable one or not
    function acceptsToken(address tokenAddress) public view {
      return tokenAddressIndex[tokenAddress]>0;
    }

    /// @notice Transfers token from Idea to recipient. 
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

    /// @notice Transfers ether from Idea to recipient
    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }


    // @notice Sets a new address of the Administrable, which controls all unknown function calls and the Idea itself.
    function _setAdministrable(address _administrable) internal {
        administrable = _administrable;
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize() internal {
        active = false; // stops trading of Shards
        emit EntityLiquidized();
    }

    // Calls an Administrable.processTokenReceipt, since it else doesn't know about the Idea Receipt.
    // Idea.receiveToken() => Idea._processTokenReceipt() => Administrable.processTokenReceipt()
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) internal {
        // First: Liquid logic
        liquid[tokenAddress].originalValue += value;
        administrable.processTokenReceipt(tokenAddress, value, from);
        emit TokenReceived(tokenAddress,value,from);
    }

    // Does NOT call an Administrable.processTokenTransfer, since transfer calls always stem from there
    // Administrable.transferToken() => Idea.transferToken() + Administrable._processTokenTransfer() => Idea._processTokenTransfer()
    function _processTokenTransfer(address tokenAddress, uint256 value, address to) internal {
        // First: Liquidization logic
        liquid[tokenAddress].originalValue -= value;
        if (liquid[tokenAddress].originalValue == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        emit TokenTransfered(tokenAddress,value,to);
    }

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

    function _unregisterTokenAddress(address tokenAddress) {
        require(acceptsToken(tokenAddress), "Token address '"+string(tokenAddress)+"' NOT registered!");
        require(liquid[tokenAddress].originalValue == 0, "Token amount must be 0 before unregistering!");

        tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1]; // -1 to distinguish between empty values;
        tokenAddressIndex[tokenAddress] = 0; // a stored index value of 0 means empty
        tokenAddress.pop();
    }

}
