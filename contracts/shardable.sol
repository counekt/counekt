pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Fractional Math

/// @notice A struct representing a fraction
/// @param numerator The numerator.
/// @param denominator The denominator.
struct Fraction {
        uint256 numerator;
        uint256 denominator;
}

/// @notice Returns the quotient and the remainder of a division. Useful for dividing ether and tokens.
/// @param dividend The dividend, which will be divided by the divisor.
/// @param divisor The divisor, which the dividend will be divided into.
function divideEquallyWithRemainder(uint256 dividend, uint256 divisor) returns(uint256, uint256) {
    uint256 quotient = dividend/divisor;
    uint256 remainder = dividend - quotient;
    return (quotient, remainder);
}

/// @notice Returns the two quotients and the remainder of an uneven division with a fraction. Useful for dividing ether and tokens.
/// @param dividend The dividend, which will be divided by the fraction.
/// @param fraction The fraction, which the dividend will be divided into.
function divideUnequallyIntoTwoWithRemainder(uint256 dividend, Fraction fraction) returns(uint256, uint256, uint256) {
    require(fraction.denominator > fraction.numerator);
    uint256 quotient1 = dividend*fraction.numerator/fraction.denominator;
    uint256 quotient2 = dividend*(fraction.denominator-fraction.numerator)/fraction.denominator;
    uint256 remainder = dividend - (quotient1 + quotient2);
    return (quotient1,quotient2,remainder);
}

/// @notice Returns the common denominator between two integers.
/// @param a First integer.
/// @param b Second integer.
function getCommonDenominator(uint256 a, uint256 b) pure returns(uint256) {
        while (b) {
        a,b = b, a % b;
        }
        return a;
}

/// @notice Returns a simplified version of a fraction.
/// @param fraction The fraction to be simplified.
function simplifyFraction(Fraction fraction) constant pure returns(Fraction) {
    uint256 commonDenominator = getCommonDenominator(fraction.numerator,fraction.denominator);
    return new Fraction(fraction.numerator/commonDenominator,fraction.denominator/commonDenominator);
}

/// @notice Adds two fractions together.
/// @param a First fraction.
/// @param b Second fraction.
function addFractions(Fraction a, Fraction b) constant pure returns (Fraction) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator,
    return new Fraction(a.numerator+b.numerator,a.denominator*b.denominator);
}

/// @notice Subtracts a fraction from another and returns the difference.
/// @param a The minuend fraction to be subtracted from.
/// @param b The subtrahend fraction that subtracts from the minuend.
function subtractFractions(Fraction a, Fraction b) constant pure returns (Fraction) {
    return addFractions(a,new Fraction(-b.numerator,b.denominator));
}


/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev historicShards are used to show proof of ownership at different points of time.
/// @custom:beaware This is a commercial contract.
contract Shardable {

    /// @notice A non-fungible token that makes it possible via a fraction to represent ownership of the Shardable entity. All of these variables are constant throughout the Shard's lifetime.
    struct Shard {
        Fraction public fraction;
        address owner; 
        uint256 creationTime;
    }

    /// @notice A struct representing the dynamic (non-constant) info of a Shard struct.
    /// @param expiredTime The block.timestamp in which the Shard expired. Default is set to the maximum value.
    /// @param forSale Boolean value stating if the Shard is for sale or not.
    /// @param forSaleTo Address pointing to a potentially specifically set buyer of the sale.
    /// @param fractionForSale Fraction that is for sale. If it's the same as Shard.fraction, then a 100% of it is for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param salePrice The amount which the Shard is for sale as. The token address being the valuta.
    struct DynamicInfo {
        uint256 expiredTime = type(uint256).max; // The maximum value: (2^256)-1
        bool public forSale;
        address public forSaleTo;
        Fraction public fractionForSale;
        address public tokenAddress;
        uint256 public salePrice;
    }

    /// @notice A boolean stating if the Shardable is active or not - changeable and tradeable or not.
    bool active = true;

    /// @notice Array containing all the currently valid Shard instances.
    Shard[] internal shards;
    /// @notice Mapping pointing to an index in the 'shards' array, given a unique Shard instance. It starts from 1 and up to differentiate between empty values.
    mapping(Shard => uint256) shardIndex;
    /// @notice Mapping pointing to a boolean value stating if a Shard has ever been valid, given a unique Shard instance.
    mapping(Shard => bool) historicShards;
    /// @notice Mapping pointing to a currently valid shard given the address of its owner.
    mapping(address => Shard) shardByOwner;
    /// @notice Mapping pointing to dynamic info of a Shard given a unique Shard instance.
    mapping(Shard => DynamicInfo) public dynamicInfo;

    /// @notice Event emitted when a Shard is split into two and fractionally transferred.
    event SplitMade(
        Shard shard,
        Fraction fraction,
        address to
        );

    /// @notice Event emitted when a sale of a Shard is sold.
    event SaleSold(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to
        );

    /// @notice Event emitted when a Shard is put up for sale.
    event PutForSale(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to,
        );

    /// @notice Event emitted when a sale of a Shard is cancelled.
    event SaleCancelled(Shard shard);

    /// @notice Event emitted when the current validity of a Shard has expired.
    event Expired(
        Shard shard,
        address holder
        );
    
    /// @notice Modifier that requires the msg.sender to be a current valid shard holder.
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
    }

    /// @notice Modifier that requires a given shard to be currently valid.
    modifier onlyValidShard(Shard shard) {
        require(isValidShard(shard), "must be a valid shard!");
    }

    /// @notice Modifier that requires the entity to be active and not liquidized/dissolved
    modifier onlyIfActive() {
        require(active == true, "Idea has been liquidized and isn't active anymore.");
    }

    /// @notice Modifier that requires the msg.sender to be the owner of a given shard
    /// @param shard The shard, whose ownership is tested for.
    modifier onlyHolder(Shard shard) {
        require(shard.owner == msg.sender.address);
    }

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    constructor() public{
        // passes full ownership to creator of contract
        _pushShard(new Shard(Fraction(1,1), msg.sender, block.timestamp));
    }

    /// @notice Fallback function that reverts any calls to non-registered functions.
    /// @dev This is rewritten in the Idea contract.
    fallback() external {
        revert;
    }

    /// @inheritdoc _putForSale
    function putForSale(Shard shard, Fraction fraction, address tokenAddress, uint256 price) external onlyHolder(shard) {
        _putForSale(shard,tokenAddress,price,fraction);
    }

    /// @inheritdoc _putForSaleTo
    function putForSaleTo(Shard shard, Fraction fraction, address tokenAddress, uint256 price, address to) external onlyHolder(shard) {
        _putForSaleTo(shard,tokenAddress,price,fraction,to);
    }

    /// @inheritdoc _cancelSale
    function cancelSale() onlyOwner {
        _cancelSale();
        emit SaleCancelled();
    }

    /// @notice Purchases a listed Shard for sale.
    /// @param shard The shard, of which a fraction will be purchased.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    function purchase(Shard shard) external payable onlyIfActive onlyValidShard(shard) {
        require(dynamicInfo[shard].forsale, "Not for sale");
        require(dynamicInfo[shard].forSaleTo == msg.sender.address || !dynamicInfo[shard].forSaleTo, string.concat("Only for sale to "+string(address)));
        _cancelSale();
        (uint256 profitToCounekt, uint256 profitToSeller, uint256 remainder) = divideUnequallyIntoTwoWithRemainder(dynamicInfo[shard].salePrice,Fraction(25,1000));
        profitToSeller += remainder; // remainder goes to seller
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

    /// @inheritdoc _split
    function split(Shard shard, Fraction toBeSplit, address to) external onlyHolder(shard) {
        _split(shard, toBeSplit, to);
    }

    /// @inheritdoc _transferShard
    function transferShard(Shard shard, address to) external onlyHolder(shard) {
        _transferShard(shard,to)
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isValidShard(Shard shard) view returns(bool) {
        return shardIndex[shard] > 0;
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract
    /// @param shardHolder The address to be checked
    /// @return A boolean value - a shard holder or not. 
    function isShardHolder(address shardHolder) view returns(bool) {
        return shardIndex[shardHolder] != 0;
    }

    /// @notice Returns a boolean stating if a given shard has ever been valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isHistoricShard(Shard shard) view returns(bool) {
        return historicShards[shard];
    }

    /// @notice Returns a boolean stating if the given shard was valid at a given timestamp.
    /// @param shard The shard, whose validity is to be checked for.
    /// @param time The timestamp to be checked for.
    function shardExisted(Shard shard, uint256 time) view returns(bool) {
        return shard.creationTime <= time < shard.deathTime;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param toBeSplit The absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _split(Shard senderhard, Fraction toBeSplit, address to) internal {
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

    /// @notice Sends a whole shard to a receiver.
    /// @param senderShard The shard to be transferred.
    /// @param to The receiver of the new Shard.
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

    /// @notice Puts a given shard for sale.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    function _putForSale(Shard shard,  Fraction fraction, address tokenAddress, uint256 price) internal onlyValidShard(shard) onlyIfActive {
        require(fraction.numerator/fraction.denominator >= shard.fraction.numerator/shard.fraction.denominator, "Can't put more than 100% of shard's fraction for sale!");
        Fraction memory simplifiedFraction = simplifyFraction(fraction);
        dynamicInfo[shard].fractionForSale = simplifiedFraction;
        dynamicInfo[shard].tokenAddress = tokenAddress;
        dynamicInfo[shard].salePrice = price;
        dynamicInfo[shard].forsale = True;
        emit PutForSale(shard,simplifiedFraction,tokenAddress,price,dynamicInfo[shard].forsaleTo);
    }

    /// @inheritdoc _putForSale
    /// @notice Puts a given shard for sale only to a specifically set buyer.
    /// @param to The specifically set buyer of the sale.
    function _putForSaleTo(Shard shard, Fraction fraction, address to, address tokenAddress, uint256 price) internal onlyValidShard(shard) onlyIfActive {
        dynamicInfo[shard].forSaleTo = to;
        _putForSale(shard,fraction,tokenAddress,price);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function _cancelSale(Shard shard) internal onlyValidShard(shard) onlyIfActive{
        require(dynamicInfo[shard].forsale == true, "Shard not even for sale!");
        dynamicInfo[shard].forSale = false;
        dynamicInfo[shard].forSaleTo = 0x0;
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    function _pushShard(Shard _shard) internal {
        shardIndex[_shard] = shards.length+1;
        shards.push(_shard);
        shardByOwner[shard.owner] = shard;
        historicShards[shard] = true;
    }

    /// @notice Removes a shard from the registry of currently valid shards. It will still remain as a historically valid shard.
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