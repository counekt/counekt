pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";

/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev Develop a way in which Shards are registered differently when traded
/// @custom:beaware This is a commercial contract.
contract Shardable {
    
    Shard[] internal shards;
    mapping(Shard => uint256) shardIndex; // starts from 1 and up to keep consistency
    mapping(Shard => bool) validShards;
    mapping(address => Shard) shardByOwner;

    bool active = true;

    constructor() {
        // pass full ownership to creator of contract
        _pushShard(new Shard(1,1, msg.sender));
    }

    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
    }

    modifier onlyValidShard {
        require(isValidShard(msg.sender), "msg.sender must be a valid shard!");
    }

    /// @dev Better
    function splitShard(address to, Fraction toBeSplit) external onlyValidShard {
        Shard memory senderShard = msg.sender;
        require(toBeSplit.numerator/toBeSplit.denominator < senderShard.fraction.numerator/senderShard.fraction.denominator, "Can't split 100% or more of shard's fraction");
        address memory sender = senderShard.owner;
        bool memory receiverIsShardHolder = isShardHolder(to);
        Fraction memory newReceiverFraction;
        
        if (receiverIsShardHolder) { // if Receiver already owns a shard
            Shard memory receiverShard = shardByOwner[to];
            
            newReceiverFraction = addFractions(receiverShard.fraction,toBeSplit); // The fractions are added and upgraded
            
            // Destroy the Old Receiver Shard
            _removeShard(receiverShard); 
            receiverShard.burn();

        }

        else {
            // The Fraction of the Receiver Shard is equal to the one split off of the Sender Shard
            newReceiverFraction = toBeSplit; 
        }

        // The new Fraction of the Sender Shard has been subtracted by the Split Fraction.
        Fraction newSenderFraction = subtractFractions(senderShard.fraction,toBeSplit);

        // Destroy the old Sender Shard
        _removeShard(senderShard); 
        senderShard.burn();

        // Push the new Shards
        Shard newReceiverShard = new Shard(newReceiverFraction,to);
        Shard newSenderShard = new Shard(newSenderFraction,sender);
        _pushShard(newReceiverShard);
        _pushShard(newSenderShard);
        }

    }

    function removeShard() external onlyValidShard {
        Shard shard = msg.sender;
        _removeShard(shard);
    }

    function isValidShard(Shard shard) returns(bool) {
        return validShards[shard];
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract
    /// @param _shardHolder The address to be checked
    /// @return A boolean value - a shard holder or not. 
    function isShardHolder(address _shardHolder) returns(bool) {
        return shardByOwner[_shardholder] != Shard(0x0);
    }

    function _pushShard(Shard _shard) internal {
        shardIndex[_shard] = shards.length+1;
        shards.push(_shard);
        shardByOwner[shard.owner] = shard;
        validShards[shard] = true;
    }

    function _removeShard(Shard shard) internal {
        require(isValidShard(shard), "Shard must be valid!");
        shardByOwner[shard.owner] = 0;
        Shard memory lastShard = shards[shards.length-1];
        shards[shardIndex[_shard]-1] = lastShard; // move last element in array to shard's place // -1 because stored indices starts from 1
        shardIndex[lastShard] = shardIndex[shard]; // configure the index to show that as well
        shardIndex[shard] = 0;
        shards.pop();
        validShards[shard] = false;
    }


    function _processShardTransfer(Shard shard, address to) internal {
        require(validShards[shard], "Shard is not valid!");
        shardByOwner[shard.owner] = Shard(0x0);
        shardByOwner[to] = shard;
    }

}


/// @title A non-fungible token that makes it possible via a fraction to represent ownership of a Shardable contract
/// @inheritdoc Shardable
contract Shard is ERC721, ERC721Burnable, Ownable {
    Shardable public shardable;
    bool public forSale = false;
    address public forSaleTo;
    uint256 public salePrice;

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    Fraction public fraction;
    Fraction public fractionForsale;

    constructor(Fraction _fraction, address holder) ERC721("Shard", "SH") {
        require(_fraction.denominator > 0);
        require(1 <= _fraction.numerator/_fraction.denominator > 0);
        shardable = msg.sender;
        fraction = _fraction;
        _transferOwnership(holder);
    }

    modifier onlyShardable {
        require(msg.sender == shardable);
    }

    modifier onlyIfShardableIsActive {
        require(shardable.active, "Shardable isn't active!")
    }

    event SplitMade(
        address to,
        Fraction fraction
        );

    event SaleSold(
        address indexed to,
        uint256 price,
        Fraction fraction
        );

    event PutForSale(
        address indexed to,
        Fraction fraction,
        uint256 price
        );

    event SaleCancelled();

    event Burned(
        Shardable shardable,
        address holder
        );

    function putForSaleTo(address to, uint256 price, uint256 _numerator, uint256 _denominator) external onlyOwner onlyIfShardableIsActive {
        forSaleTo = to;
        putForSale(price,Fractíon(_numerator,_denominator));
    }

    function putForSale(uint256 price, uint256 _numerator, uint256 _denominator) external onlyOwner onlyIfShardableIsActive {
        require(_numerator/_denominator >= fraction.numerator/fraction.denominator, "Can't put for sale more than shard's fraction");
        fractionForsale = Fraction(simplify(_numerator, _denominator));
        salePrice = price;
        forsale = True;
        emit PutForSale(forSaleTo,price,Fraction(_numerator,_denominator));
    }


    function cancelSell() onlyOwner {
        _cancelSell();
        emit SellCancelled();
    }

    function purchase() external payable onlyIfShardableIsActive {
        require(forsale, "Not for sale");
        require(forSaleTo == msg.sender.address || !forSaleTo, string.concat("Only for sale to "+string(address)));
        require(msg.value >= salePrice, "Not enough paid");
        _cancelSell();
        // Pay Service Fee of 2.5% to Counekt
        (bool success, ) = address(0x49a71890aea5A751E30e740C504f2E9683f347bC).call.value(msg.value*0.025)("");
        require(success, "Transfer failed.");
        _split(msg.sender, fractionForsale);
        emit SaleSold({to: msg.sender.address, numerator: fractionForsale.numerator, denominator: fractionForsale.denominator, price: salePrice});
    }


    function split(address to, uint256 _numerator, uint256 _denominator) external onlyOwner onlyIfShardableIsActive {
        _split(to,Fraction(_numerator,_denominator));
        emit SplitMade(to,_numerator,_denominator);
    }

    function transferOwnership(address to) external onlyOwner {
        _transferOwnership(to);
        shardable._processShardTransfer(to);
    }

    function burn() external onlyShardable {
        _burn();
    }

    function _split(address to, Fraction toBeSplit) internal {
        shardable.splitShard(to,toBeSplit);
    }

    function _cancelSell() internal {
        forSale = false;
        forSaleTo = 0x0;
    }

    function _burn() internal {
        super._burn();
    }

    function isEmpty() returns(bool) {
        return getDecimal() == 0;
    }

    function getDecimal() view returns(uint256) {
        return fraction.numerator/fraction.denominator;
    }
}

// Fractional Math

function getCommonDenominator(uint256 a, uint256 b) pure returns(uint256) {
        while (b) {
        a,b = b, a % b;
        }
        return a;
}

function simplifyFraction(Fraction _fraction) pure returns(Fraction) {
    commonDenominator = getCommonDenominator(_fraction.numerator,_fraction.denominator);
    return new Fraction(_fraction.numerator/commonDenominator,_fraction.denominator/commonDenominator);
}

function addFractions(Fraction a, Fraction b) pure returns (Fraction) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator,
    return new Fraction(a.numerator+b.numerator,a.denominator*b.denominator);
}

function subtractFractions(Fraction a, Fraction b) pure returns (Fraction) {
    return addFractions(a,new Fraction(-b.numerator,b.denominator));
}