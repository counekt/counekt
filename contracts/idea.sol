pragma solidity ^0.8.4;

import "../versionControl.sol";
import "../shardable.sol";


/// @title A proof of fractional ownership of an entity with valuables (administered by Administerable).
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable business entity. 
/// @custom:illustration Idea => Idea.Administration => Idea
/// @custom:beaware This is a commercial contract.
contract Idea is Shardable {

	constructor(string administrationType) {
		administration = VersionAdmin.createVersion(administrationType);
	}

	// Administration
	// this is the contract from which the Idea is administered.
	address administration;

	// Liquidization keeps track of all tokens
    // is updated along the way
    mapping(address => Dividend) liquidization;
    address[] tokenAddresses;
    mapping(address => uint256) tokenAddressIndex; // starts from 1 and up, to differentiate betweeen empty values

    modifier onlyAdministerable {
    	require(msg.sender == administerable);
    }

    /// @notice Receives money when there's no supplying data and puts it into the 'main' bank 
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processTokenReceipt("main",address(0),msg.value,msg.sender);
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

    function receiveToken(string bankName, address tokenAddress, uint256 value) external {
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(bankName,tokenAddress,value,msg.sender);
    }


}
