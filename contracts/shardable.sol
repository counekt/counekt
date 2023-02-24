pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


// Fractional Math

struct Fraction {
        uint256 numerator;
        uint256 denominator;
}

function getDecimal(Fraction fraction) view returns(uint256) {
        return fraction.numerator/fraction.denominator;
    }

function getCommonDenominator(uint256 a, uint256 b) pure returns(uint256) {
        while (b) {
        a,b = b, a % b;
        }
        return a;
}

function simplifyFraction(Fraction fraction) pure returns(Fraction) {
    commonDenominator = getCommonDenominator(fraction.numerator,fraction.denominator);
    return new Fraction(fraction.numerator/commonDenominator,fraction.denominator/commonDenominator);
}

function addFractions(Fraction a, Fraction b) pure returns (Fraction) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator,
    return new Fraction(a.numerator+b.numerator,a.denominator*b.denominator);
}

function subtractFractions(Fraction a, Fraction b) pure returns (Fraction) {
    return addFractions(a,new Fraction(-b.numerator,b.denominator));
}


/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev historicShards are used to show proof of ownership at different points of time.
/// @custom:beaware This is a commercial contract.

contract Shardable {

    /// @title A non-fungible token that makes it possible via a fraction to represent ownership of a Shardable entity
    // All of these variables are constant throughout the Shard's lifetime.
    struct Shard {
        Fraction public fraction;
        address owner; // Shard Holder
        uint256 creationTime;
    }

    struct DynamicInfo {
        uint256 expiredTime = uint256(int256(-1)); // The maximum value: (2^256)-1
        bool public forSale;
        address public forSaleTo;
        Fraction public fractionForSale;
        address public tokenAddress;
        uint256 public salePrice;
    }

    bool active = true;

    Shard[] internal shards;
    mapping(Shard => uint256) shardIndex; // starts from 1 and up to keep consistency
    mapping(Shard => bool) historicShards;
    mapping(address => Shard) shardByOwner;
    mapping(Shard => DynamicInfo) dynamicInfo;

    event SplitMade(
        Shard shard,
        Fraction fraction,
        address to
        );

    event SaleSold(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to
        );

    event PutForSale(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to,
        );

    event SaleCancelled();

    event Expired(
        Shard shard,
        address holder
        );
    
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
    }

    modifier onlyValidShard(Shard shard) {
        require(isValidShard(shard), "must be a valid shard!");
    }

    // modifier to make sure entity is active and not liquidized/dissolved
    modifier onlyIfActive() {
        require(idea.active == true, "Idea has been liquidized and isn't active anymore.");
    }

    modifier onlyHolder(Shard shard) {
        shard.owner == msg.sender.address;
    }

    constructor() public{
        // passes full ownership to creator of contract
        _pushShard(new Shard(Fraction(1,1), msg.sender, block.timestamp));
    }

    function putForSale(Shard shard, Fraction fraction, address tokenAddress, uint256 price) external onlyHolder(shard) {
        _putForSale(shard,tokenAddress,price,fraction);
    }

    function putForSaleTo(Shard shard, Fraction fraction, address tokenAddress, uint256 price, address to) external onlyHolder(shard) {
        _putForSaleTo(shard,tokenAddress,price,fraction,to);
    }

    function cancelSell() onlyOwner {
        _cancelSell();
        emit SellCancelled();
    }

    /// @notice Purchases a listed Shard for sale.
    /// @param shard The shard, of which a fraction will be purchased.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    function purchase(Shard shard) external payable onlyIfActive onlyValidShard(shard) {
        require(dynamicInfo[shard].forsale, "Not for sale");
        require(dynamicInfo[shard].forSaleTo == msg.sender.address || !dynamicInfo[shard].forSaleTo, string.concat("Only for sale to "+string(address)));
        _cancelSell();
        uint256 profitToCounekt = dynamicInfo[shard].salePrice*0.025;
        uint256 profitToSeller = dynamicInfo[shard].salePrice - profitToCounekt;
        // if ether
        if (dynamicInfo[shard].tokenAddress == 0x0) {
            require(msg.value >= dynamicInfo[shard].salePrice, "Not enough ether paid");
            // Pay Service Fee of 2.5% to Counekt
            (bool success, ) = payable(0x49a71890aea5A751E30e740C504f2E9683f347bC).call.value(profitToCounekt)("");
            require(success, "Transfer failed.");
            // Rest goes to the seller
            (bool success, ) = payable(shard.owner).call.value(profitToSeller)("");
            require(success, "Transfer failed.");
        } 
        else {
            token = ERC20(dynamicInfo[shard].tokenAddress);
            // Pay Service Fee of 2.5% to Counekt
            token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt);
            // Rest goes to the seller
            token.transferFrom(msg.sender,shard.owner,profitToSeller);
        } 
        if (dynamicInfo[shard].fraction == dynamicInfo[shard].fractionForSale) {transferShard(shard,msg.sender);}
        else {splitShard(msg.sender, dynamicInfo[shard].fractionForSale);}
        emit SaleSold(shard,dynamicInfo[shard].fractionForSale,dynamicInfo[shard].tokenAddress,dynamicInfo[shard].salePrice,msg.sender);
    }

    function split(Shard shard, Fraction toBeSplit, address to) external onlyHolder(shard) {
        _split(shard, toBeSplit, to);
    }

    function transferShard(Shard shard, address to) external onlyHolder(shard) {
        _transferShard(shard,to)
    }

    function isValidShard(Shard shard) returns(bool) {
        return shardIndex[shard] > 0;
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract
    /// @param shardHolder The address to be checked
    /// @return A boolean value - a shard holder or not. 
    function isShardHolder(address shardHolder) returns(bool) {
        return shardIndex[shardHolder] != 0;
    }

    function isHistoricShard(Shard shard) returns(bool) {
        return historicShards[shard];
    }

    function shardExisted(Shard shard, uint256 time) returns(bool) {
        return shard.creationTime <= time < shard.deathTime;
    }

    function _split(Shard shard, Fraction toBeSplit, address to) internal {
        require(toBeSplit.numerator/toBeSplit.denominator < senderShard.fraction.numerator/senderShard.fraction.denominator, "Can't split 100% or more of shard's fraction");
        uint256 transferTime = block.timestamp;
        require(transferTime > shard.creationTime, "Can't trade more than once per second! The shard to be split must be more than one second old. Wait a second.");

        address memory sender = senderShard.owner;
        bool memory receiverIsShardHolder = isShardHolder(to);
        Fraction memory newReceiverFraction;

        if (receiverIsShardHolder) { // if Receiver already owns a shard
            Shard memory receiverShard = shardByOwner[to];
            require(transferTime > receiverShard.creationTime , "Can't trade more than once per second! The receiver's shard must be more than one second old. Wait a second.");

            newReceiverFraction = addFractions(receiverShard.fraction,toBeSplit); // The fractions are added and upgraded
            
            // Expire the Old Receiver Shard
            _expireShard(receiverShard); 

        }

        else {
            // The Fraction of the Receiver Shard is equal to the one split off of the Sender Shard
            newReceiverFraction = toBeSplit; 
        }

        // The new Fraction of the Sender Shard has been subtracted by the Split Fraction.
        Fraction newSenderFraction = subtractFractions(senderShard.fraction,toBeSplit);

        // Expire the Old Sender Shard
        _expireShard(senderShard); 

        // Push the new Shards
        Shard newReceiverShard = new Shard(newReceiverFraction,to,transferTime);

        Shard newSenderShard = new Shard(newSenderFraction,sender,transferTime);
        _pushShard(newReceiverShard);
        _pushShard(newSenderShard);
        }
    }

    function _transferShard(Shard senderShard, address to) {
        uint256 transferTime = block.timestamp;
        Fraction newReceiverFraction;
        if (isShardHolder(to)) {
            Shard memory receiverShard = shardByOwner[to];

            // Destroying the Old receiver
            _removeShard(receiverShard);
            receiverShard.expire(transferTime);

            newReceiverFraction = addFractions(senderShard.fraction,receiverShard.fraction); // The fractions are added and upgraded
        
        }
        else {
            newReceiverFraction = senderShard.fraction;
        }

        // Destroying the Old sender
        _removeShard(senderShard);
        senderShard.expire(transferTime);

        // Creating the New
        Shard newReceiverShard = new Shard(newReceiverFraction,to,transferTime);
        _pushShard(newReceiverShard);
    }

    function _putForSale(Shard shard,  Fraction fraction, address tokenAddress, uint256 price) internal onlyValidShard(shard) onlyIfActive {
        require(fraction.numerator/fraction.denominator >= shard.fraction.numerator/shard.fraction.denominator, "Can't put more than 100% of shard's fraction for sale!");
        Fraction memory simplifiedFraction = simplifyFraction(fraction);
        dynamicInfo[shard].fractionForSale = simplifiedFraction;
        dynamicInfo[shard].tokenAddress = tokenAddress;
        dynamicInfo[shard].salePrice = price;
        dynamicInfo[shard].forsale = True;
        emit PutForSale(shard,simplifiedFraction,tokenAddress,price,dynamicInfo[shard].forsaleTo);
    }

    function _putForSaleTo(Shard shard, Fraction fraction, address to, address tokenAddress, uint256 price, ) internal onlyValidShard(shard) onlyIfActive {
        dynamicInfo[shard].forSaleTo = to;
        _putForSale(shard,fraction,tokenAddress,price);
    }

    function _cancelSell(Shard shard) internal onlyValidShard(shard) onlyIfActive{
        require(dynamicInfo[shard].forsale == true, "Shard not even for sale!");
        dynamicInfo[shard].forSale = false;
        dynamicInfo[shard].forSaleTo = 0x0;
    }

    function _pushShard(Shard _shard) internal {
        shardIndex[_shard] = shards.length+1;
        shards.push(_shard);
        shardByOwner[shard.owner] = shard;
        historicShards[shard] = true;
    }

    function _removeShard(Shard shard) internal {
        require(isValidShard(shard), "Shard must be valid!");
        shardByOwner[shard.owner] = Shard();
        Shard memory lastShard = shards[shards.length-1];
        shards[shardIndex[shard]-1] = lastShard; // move last element in array to shard's place // -1 because stored indices starts from 1
        shardIndex[lastShard] = shardIndex[shard]; // configure the index to show that as well
        shardIndex[shard] = 0;
        shards.pop();
    }

}