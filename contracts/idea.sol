pragma solidity ^0.8.4;

import "../versionControl.sol";
import "../shardable.sol";


/// @title A proof of fractional ownership of an entity with valuables (administered by Administerable).
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

	constructor(string administrableType) {
		administrable = VersionAdmin.createVersion(administrableType, this.address);
	}

	// Administration
	// this is the contract from which the Idea is administered.
	address administrable;

	// Liquidization keeps track of all tokens
    // is updated along the way
    mapping(address => TokenRegister) liquid;
    address[] tokenAddresses;
    mapping(address => uint256) tokenAddressIndex; // starts from 1 and up, to differentiate betweeen empty values

    struct TokenRegister {
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) hasClaimed; // Ín case of liquidization - Shard Holders claim their fair share of the value.
    }

    modifier onlyAdministrable {
    	require(msg.sender == administrable);
    }
    
    // when calling an unknown function, idea calls administrable
    // idea => administrable => idea
    fallback() external {
      administrable.call(msg.data);
    }

    /// @notice Receives money when there's no supplying data and puts it into the 'main' bank 
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processTokenReceipt("main",address(0),msg.value,msg.sender);
    }

    function receiveToken(address tokenAddress, uint256 value) external {
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(tokenAddress,value,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction when the entity has been liquidized/dissolved.
    /// @inheritdoc _liquidize
    /// @dev NOT UP TO DATE WITH THE TOKEN ECOSYSTEM IMPLEMENTATION
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

    function transferToken(address tokenAddress, uint256 value, address to) external onlyAdministrable {
        _transferToken(tokenAddress,value,to);
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function liquidize() external onlyAdministrable {
        _liquidize(by);
    }

    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) { _transferEther(value, to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "Failed to approve transfer");
            if (isIdea(to)) {
                Idea(to).receiveToken("main", tokenAddress, value);
            }

        }
    }

    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize() internal {
        active = false; // stops trading of Shards
        emit EntityLiquidized();
    }


    function _processTokenReceipt(address tokenAddress, uint256 value, address from) internal onlyExistingBank(toBankName) {
        // First: Liquid logic
        if (tokenAddressIndex[tokenAddress] != 0) {
            _registerTokenAddress(tokenAddress);
        }
        else {
            liquid[tokenAddress].originalValue += value;
        }
        administrable.processTokenReceipt(tokenAddress, value, from);
        emit TokenReceived(tokenAddress,value,from);
    }

    function _processTokenTransfer(address tokenAddress, uint256 value, address to) internal {
        // First: Liquidization logic
        liquid[tokenAddress].originalValue -= value;
        if (liquid[tokenAddress].originalValue == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        emit TokenTransfered(fromBankName,tokenAddress,value,to,by);
    }

    function _registerTokenAddress(address tokenAddress) {
        require(tokenAddressIndex[tokenAddress] == 0, "Token address '"+string(tokenAddress)+"' ALREADY registered!");
        tokenAddressIndex[tokenAddress] = tokenAddresses.length + 1; // +1 to distinguish between empty values;
        tokenAddresses.push(tokenAddress);
        // Update liquidization
        TokenRegister newTokenRegister = new TokenRegister();
        newTokenRegister.tokenAddress = tokenAddress;
        newTokenRegister.originalValue = value;
        liquid[tokenAddress] = newTokenRegister;
    }

    function _unregisterTokenAddress(address tokenAddress) {
        require(tokenAddressIndex[tokenAddress] > 0, "Token address '"+string(tokenAddress)+"' NOT registered!");
        require(liquid[tokenAddress].originalValue == 0, "Token amount must be 0 before unregistering!");

        tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1]; // -1 to distinguish between empty values;
        tokenAddressIndex[tokenAddress] = 0; // a stored index value of 0 means empty
        tokenAddress.pop();
    }

}
