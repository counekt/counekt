pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";


// Fractional Math

/// @notice A struct representing a fraction.
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
/// @param fraction The Fraction, which the dividend will be divided into.
function divideUnequallyIntoTwoWithRemainder(uint256 dividend, Fraction memory fraction) returns(uint256, uint256, uint256) {
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
        (a, b) = (b, a % b);
        }
        return a;
}

/// @notice Returns a simplified version of a fraction.
/// @param fraction The fraction to be simplified.
function simplifyFraction(Fraction memory fraction) pure returns(Fraction memory) {
    uint256 commonDenominator = getCommonDenominator(fraction.numerator,fraction.denominator);
    return new Fraction(fraction.numerator/commonDenominator,fraction.denominator/commonDenominator);
}

/// @notice Adds two fractions together.
/// @param a First fraction.
/// @param b Second fraction.
function addFractions(Fraction memory a, Fraction memory b) pure returns (Fraction memory) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator;
    return new Fraction(a.numerator+b.numerator,a.denominator*b.denominator);
}

/// @notice Subtracts a fraction from another and returns the difference.
/// @param a The minuend fraction to be subtracted from.
/// @param b The subtrahend fraction that subtracts from the minuend.
function subtractFractions(Fraction memory a, Fraction memory b) pure returns (Fraction memory) {
    return addFractions(a,new Fraction(-b.numerator,b.denominator));
}


/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev historicShards are used to show proof of ownership at different points of time.
/// @custom:beaware This is a commercial contract.
contract Shardable {

    /// @notice A non-fungible token that makes it possible via a fraction to represent ownership of the Shardable entity. All of these variables are constant throughout the Shard's lifetime.
    /// @dev Is represented via a bytes32 value created from the hash: keccak256(owner, creationTime).
    /// @param fraction The fraction of the Shardable that the Shard represents.
    /// @param owner The owner of the Shard.
    /// @param creationTime The block.timestamp at which the Shard was created.
    struct Shard {
        Fraction fraction;
        address owner; 
        uint256 creationTime;
    }

    /// @notice A struct representing the dynamic (non-constant) info of a Shard struct.
    /// @param expiredTime The block.timestamp at which the Shard expired. Default is set to the maximum value.
    /// @param forSale Boolean value stating if the Shard is for sale or not.
    /// @param forSaleTo Address pointing to a potentially specifically set buyer of the sale.
    /// @param fractionForSale Fraction that is for sale. If it's the same as Shard.fraction, then a 100% of it is for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param salePrice The amount which the Shard is for sale as. The token address being the valuta.
    struct DynamicShardInfo {
        uint256 expiredTime;
        bool forSale;
        address forSaleTo;
        Fraction fractionForSale;
        address tokenAddress;
        uint256 salePrice;
    }

    /// @notice Boolean stating if the Shardable is active and tradeable or not.
    bool active = true;
    /// @notice Mapping pointing to a unique Shard given the bytes of the unique Shard instance.
    mapping(bytes32 => Shard) shardByBytes;
    /// @notice Mapping pointing to a boolean value stating if a Shard is currently valid, given the bytes of a unique Shard instance.
    mapping(bytes32 => bool) public currentlyValidShards;
    /// @notice Mapping pointing to a boolean value stating if a Shard has ever been valid, given the bytes of a unique Shard instance.
    mapping(bytes32 => bool) public historicallyValidShards;
    /// @notice Mapping pointing to dynamic info of a Shard given the bytes of a unique Shard instance.
    mapping(bytes32 => DynamicShardInfo) public dynamicInfoByShard;
    /// @notice Mapping pointing to a currently valid shard given the address of its owner.
    mapping(address => bytes32) public shardByOwner;
    
    /// @notice Event emitted when a Shard is split into two and fractionally transferred.
    /// @param shard The Shard, which was split.
    /// @param fraction The absolute fraction of the splitted Shard, which was transferred to the receiver.
    /// @param to The receiver of the splitted Shard.
    event SplitMade(
        Shard shard,
        Fraction fraction,
        address to
        );

    /// @notice Event emitted when a sale of a Shard is sold.
    /// @param shard The shard that was sold from.
    /// @param fraction The absolute Fraction of the Shard that was sold.
    /// @param tokenAddress The address of the token that was accepted in the purchase. A value of 0x0 represents ether.
    /// @param price The amount which the Shard was for sale for. The token address being the valuta.
    /// @param to The buyer of the sale.
    event SaleSold(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to
        );

    /// @notice Event emitted when a Shard is put up for sale.
    /// @param shard The shard that was put for sale.
    /// @param fraction The absolute Fraction of the shard that was put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale, if any.
    event PutForSale(
        Shard shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to
        );

    /// @notice Event emitted when a sale of a Shard is cancelled.
    /// @param shard The Shard, which has been taken off sale.
    event SaleCancelled(Shard shard);
    
    /// @notice Modifier that requires the msg.sender to be a current valid Shard holder.
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
        _;
    }

    /// @notice Modifier that requires the msg.sender to have been a historic Shard holder.
    modifier onlyHistoricShardHolder {
        require(isHistoricShard(msg.sender), "msg.sender must be a valid shard holder!");
        _;
    }

    /// @notice Modifier that requires a given Shard to be currently valid.
    modifier onlyValidShard(bytes32 shardBytes) {
        require(isValidShard(shardBytes), "must be a valid shard!");
        _;
    }

    /// @notice Modifier that requires the entity to be active and not liquidized/dissolved
    modifier onlyIfActive() {
        require(active == true, "Idea has been liquidized and isn't active anymore.");
        _;
    }

    /// @notice Modifier that requires the msg.sender to be the owner of a given Shard
    /// @param shard The Shard, whose ownership is tested for.
    modifier onlyHolder(bytes32 shardBytes) {
        require(shardByBytes[shardBytes].owner == msg.sender.address);
        _;
    }

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    constructor() public{
        // passes full ownership to creator of contract
        _pushShard(new Shard(Fraction(1,1), msg.sender, block.timestamp));
    }

    /// @notice Fallback function that reverts any calls to non-registered functions.
    fallback() external {
        revert;
    }

    /// @notice Puts a given shard for sale.
    /// @param shardBytes The bytes of the shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    function putForSale(bytes32 shardBytes, Fraction fraction, address tokenAddress, uint256 price) external onlyHolder(shardBytes) {
        _putForSale(shardBytes,tokenAddress,price,fraction);
    }

    /// @notice Puts a given shard for sale only to a specifically set buyer.
    /// @param shardBytes The bytes of the shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale.
    function putForSaleTo(bytes32 shardBytes, Fraction fraction, address tokenAddress, uint256 price, address to) external onlyHolder(shardBytes) {
        _putForSaleTo(shardBytes,tokenAddress,price,fraction,to);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shardBytes The bytes of the shard to be put off sale.
    function cancelSale(bytes32 shardBytes) external onlyHolder(shardBytes) {
        _cancelSale(shard);
        emit SaleCancelled(shard);
    }

    /// @notice Purchases a listed Shard for sale.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    /// @param shardBytes The bytes of the shard, of which a fraction will be purchased.
    function purchase(bytes32 shardBytes) external payable onlyIfActive onlyValidShard(shardBytes) {
        require(dynamicInfoByShard[shardBytes].forsale, "Not for sale");
        require(dynamicInfoByShard[shardBytes].forSaleTo == msg.sender.address || !dynamicInfoByShard[shardBytes].forSaleTo, string.concat("Only for sale to "+string(address)));
        _cancelSale();
        (uint256 profitToCounekt, uint256 profitToSeller, uint256 remainder) = divideUnequallyIntoTwoWithRemainder(dynamicInfoByShard[shardBytes].salePrice,Fraction(25,1000));
        profitToSeller += remainder; // remainder goes to seller
        // if ether
        if (dynamicInfoByShard[shardBytes].tokenAddress == 0x0) {
            require(msg.value >= dynamicInfoByShard[shardBytes].salePrice, "Not enough ether paid");
            // Pay Service Fee of 2.5% to Counekt
            (bool success, ) = payable(0x49a71890aea5A751E30e740C504f2E9683f347bC).call.value(profitToCounekt)("");
            require(success, "Transfer failed.");
            // Rest goes to the seller
            (bool success, ) = payable(shard.owner).call.value(profitToSeller)("");
            require(success, "Transfer failed.");
        } 
        else {
            ERC20 token = ERC20(dynamicInfoByShard[shardBytes].tokenAddress);
            // Pay Service Fee of 2.5% to Counekt
            token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt);
            // Rest goes to the seller
            token.transferFrom(msg.sender,shardByBytes[shardBytes].owner,profitToSeller);
        } 
        if (dynamicInfoByShard[shardBytes].fraction == dynamicInfoByShard[shardBytes].fractionForSale) {_transferShard(shard,msg.sender);}
        else {_split(shardBytes, dynamicInfoByShard[shardBytes].fractionForSale,msg.sender);}
        emit SaleSold(shardBytes,dynamicInfoByShard[shardBytes].fractionForSale,dynamicInfoByShard[shardBytes].tokenAddress,dynamicInfoByShard[shardBytes].salePrice,msg.sender);
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param toBeSplit The absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function split(bytes32 shardBytes, Fraction toBeSplit, address to) external onlyHolder(shardBytes) {
        _split(shardBytes, toBeSplit, to);
        emit SplitMade(shardBytes,toBeSplit,to);
    }

    /// @notice Sends a whole shard to a receiver.
    /// @param senderShard The shard to be transferred.
    /// @param to The receiver of the new Shard.
    function transferShard(bytes32 shardBytes, address to) external onlyHolder(shardBytes) {
        _transferShard(shardBytes,to);
        emit SplitMade(shardBytes,shardByBytes[shardBytes].fraction,to);

    }
    /// @notice Returns the unique keccak256 representation of a unique Shard.
    /// @param shard The shard to be converted into a unique set of bytes.
    function getShardBytes(Shard shard) returns(bytes32) {
        return keccak256((shard.owner,shard.creationTime));
    }

    /// @notice Returns the dynamic information of a unique Shard.
    /// @param shard The shard to get the information on.
    function getDynamicShardInfo(bytes32 shardBytes) returns(DynamicShardInfo) {
        return dynamicInfoByShard[shardBytes];
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isValidShard(bytes32 shardBytes) public view returns(bool) {
        return currentlyValidShards[shardBytes];
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract.
    /// @param shardHolder The address to be checked for.
    function isShardHolder(address _address) public view returns(bool) {
        return isValidShard(shardByOwner[_address]);
    }

    /// @notice Returns a boolean stating if a given shard has ever been valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isHistoricShard(bytes32 shardBytes) public view returns(bool) {
        return historicallyValidShards[shardBytes];
    }

    /// @notice Checks if address is a historic Shard holder - at least a previous partial owner of the contract
    /// @param shardHolder The address to be checked for.
    function isHistoricShardHolder(address _address) public view returns(bool) {
        return isHistoricShard(shardByOwner[_address]);
    }

    /// @notice Returns a boolean stating if the given shard was valid at a given timestamp.
    /// @param shard The shard, whose validity is to be checked for.
    /// @param time The timestamp to be checked for.
    function shardExisted(Shard shard, uint256 time) public view returns(bool) {
        return shard.creationTime <= time < shard.deathTime;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param toBeSplit The absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _split(bytes32 senderShardBytes, Fraction toBeSplit, address to) internal {
        require(toBeSplit.numerator/toBeSplit.denominator < senderShard.fraction.numerator/senderShard.fraction.denominator, "Can't split 100% or more of shard's fraction");
        uint256 transferTime = block.timestamp;
        require(transferTime > senderShard.creationTime, "Can't trade more than once per second! The shard to be split must be more than one second old. Wait a second.");
        Shard memory senderShard = shardByBytes[senderShardBytes];
        address memory sender = senderShard.owner;
        bool memory receiverIsShardHolder = isShardHolder(to);
        Fraction memory newReceiverFraction;

        if (receiverIsShardHolder) { // if Receiver already owns a shard
            Shard memory receiverShard = shardByBytes[shardByOwner[to]];
            require(transferTime > receiverShard.creationTime , "Can't trade more than once per second! The receiver's shard must be more than one second old. Wait a second.");

            newReceiverFraction = addFractions(receiverShard.fraction,toBeSplit); // The fractions are added and upgraded
            
            // Expire the Old Receiver Shard
            _removeShard(receiverShard); 

        }

        else {
            // The Fraction of the Receiver Shard is equal to the one split off of the Sender Shard
            newReceiverFraction = toBeSplit; 
        }

        // The new Fraction of the Sender Shard has been subtracted by the Split Fraction.
        Fraction newSenderFraction = subtractFractions(senderShard.fraction,toBeSplit);

        // Expire the Old Sender Shard
        _removeShard(senderShardBytes); 

        // Push the new Shards
        Shard newReceiverShard = new Shard(newReceiverFraction,to,transferTime);

        Shard newSenderShard = new Shard(newSenderFraction,sender,transferTime);
        _pushShard(newReceiverShard);
        _pushShard(newSenderShard);
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
        DynamicShardInfo memory dynamicShardInfo = getDynamicShardInfo(shard);
        dynamicInfo.fractionForSale = simplifiedFraction;
        dynamicInfo.tokenAddress = tokenAddress;
        dynamicInfo.salePrice = price;
        dynamicInfo.forsale = true;
        emit PutForSale(shard,simplifiedFraction,tokenAddress,price,dynamicShardInfo.forsaleTo);
    }

    /// @notice Puts a given shard for sale only to a specifically set buyer.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale.
    function _putForSaleTo(Shard shard, Fraction fraction, address tokenAddress, uint256 price, address to) internal onlyValidShard(shard) onlyIfActive {
        dynamicInfoByShard[getShardBytes(shard)].forSaleTo = to;
        _putForSale(shard,fraction,tokenAddress,price);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function _cancelSale(bytes32 shardBytes) internal onlyValidShard(shardBytes) onlyIfActive{
        bytes32 memory shardBytes = getShardBytes(shard);
        require(dynamicInfoByShard[shardBytes].forsale == true, "Shard not even for sale!");
        dynamicInfoByShard[shardBytes].forSale = false;
        dynamicInfoByShard[shardBytes].forSaleTo = 0x0;
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param shard The shard to be pushed.
    function _pushShard(Shard shard) internal {
        bytes32 memory shardBytes = getShardBytes(shard);
        shardByOwner[shard.owner] = shardBytes;
        dynamicInfoByShard[shardBytes].expiredTime = type(uint256).max; // The maximum value: (2^256)-1
        currentlyValidShards[shardBytes] = true;
        historicallyValidShards[shardBytes] = true;
    }

    /// @notice Removes a shard from the registry of currently valid shards. It will still remain as a historically valid shard.
    /// @param shard The shard to be removed.
    function _removeShard(bytes32 shardBytes) internal onlyValidShard(shardBytes) {
        currentlyValidShards[shardBytes] = false;
    }

}