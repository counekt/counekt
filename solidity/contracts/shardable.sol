pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";


// Fractional Math

/// @notice A struct representing a fraction.
/// @param numerator The numerator.
/// @param denominator The denominator.
struct Fraction {
    uint256 numerator;
    uint256 denominator;
}

/// @notice Returns a boolean stating if two given fractions are identical.
/// @param a First fraction.
/// @param b Second fraction.
function fractionsAreIdentical(Fraction memory a, Fraction memory b) returns(bool) {
    return a.numerator == b.numerator && a.denominator == b.denominator;
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
        while (b > 0) {
        (a, b) = (b, a % b);
        }
        return a;
}

/// @notice Returns a simplified version of a fraction.
/// @param fraction The fraction to be simplified.
function simplifyFraction(Fraction memory fraction) pure returns(Fraction memory) {
    uint256 commonDenominator = getCommonDenominator(fraction.numerator,fraction.denominator);
    return Fraction(fraction.numerator/commonDenominator,fraction.denominator/commonDenominator);
}

/// @notice Adds two fractions together.
/// @param a First fraction.
/// @param b Second fraction.
function addFractions(Fraction memory a, Fraction memory b) pure returns (Fraction memory) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator;
    return Fraction(a.numerator+b.numerator,a.denominator*b.denominator);
}

/// @notice Subtracts a fraction from another and returns the difference.
/// @param a The minuend fraction to be subtracted from.
/// @param b The subtrahend fraction that subtracts from the minuend.
function subtractFractions(Fraction memory a, Fraction memory b) pure returns (Fraction memory) {
    a.numerator = a.numerator * b.denominator;
    b.numerator = b.numerator * a.denominator;
    return Fraction(a.numerator-b.numerator,a.denominator-b.denominator);
}


/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev historicShards are used to show proof of ownership at different points of time.
/// @custom:beaware This is a commercial contract.
contract Shardable {

    /// @notice A struct representing the related info of a non-fungible Shard token.
    /// @dev Is represented via a bytes32 value created from the hash: keccak256(owner, creationTime).
    /// @param fraction The fraction of the Shardable that the Shard represents.
    /// @param owner The owner of the Shard.
    /// @param creationTime The block.timestamp at which the Shard was created.
    /// @param expiredTime The block.timestamp at which the Shard expired. Default is set to the maximum value.
    /// @param forSale Boolean value stating if the Shard is for sale or not.
    /// @param forSaleTo Address pointing to a potentially specifically set buyer of the sale.
    /// @param fractionForSale Fraction that is for sale. If it's the same as Shard.fraction, then a 100% of it is for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param salePrice The amount which the Shard is for sale as. The token address being the valuta.
    struct ShardInfo {
        Fraction fraction;
        address owner; 
        uint256 creationTime;
        uint256 expiredTime;
        bool forSale;
        address forSaleTo;
        Fraction fractionForSale;
        address tokenAddress;
        uint256 salePrice;
    }

    /// @notice Boolean stating if the Shardable is active and tradeable or not.
    bool active = true;
    /// @notice Mapping pointing to related info of a Shard given the bytes of a unique Shard instance.
    mapping(bytes32 => ShardInfo) infoByShard;
    /// @notice Mapping pointing to a boolean value stating if a Shard is currently valid, given the bytes of a unique Shard instance.
    mapping(bytes32 => bool) public currentlyValidShards;
    /// @notice Mapping pointing to a boolean value stating if a Shard has ever been valid, given the bytes of a unique Shard instance.
    mapping(bytes32 => bool) public historicallyValidShards;
    /// @notice Mapping pointing to a currently valid shard given the address of its owner.
    mapping(address => bytes32) public shardByOwner;
    
    /// @notice Event emitted when a Shard is split into two and fractionally transferred.
    /// @param shard The Shard, which was split.
    /// @param fraction The absolute fraction of the splitted Shard, which was transferred to the receiver.
    /// @param to The receiver of the splitted Shard.
    event SplitMade(
        bytes32 shard,
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
        bytes32 shard,
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
        bytes32 shard,
        Fraction fraction,
        address tokenAddress,
        uint256 price,
        address to
        );

    /// @notice Event emitted when a sale of a Shard is cancelled.
    /// @param shard The Shard, which has been taken off sale.
    event SaleCancelled(bytes32 shard);
    
    /// @notice Modifier that requires the msg.sender to be a current valid Shard holder.
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
        _;
    }

    /// @notice Modifier that requires the msg.sender to have been a historic Shard holder.
    modifier onlyHistoricShardHolder {
        require(isHistoricShardHolder(msg.sender), "msg.sender must be a valid shard holder!");
        _;
    }

    /// @notice Modifier that requires a given Shard to be currently valid.
    modifier onlyValidShard(bytes32 shard) {
        require(isValidShard(shard), "must be a valid shard!");
        _;
    }

    /// @notice Modifier that makes sure the entity is active and not liquidized/dissolved.
    modifier onlyIfActive() {
        require(active == true, "Entity has been liquidized and isn't active anymore.");
        _;
    }

    /// @notice Modifier that requires the msg.sender to be the owner of a given Shard
    /// @param shard The Shard, whose ownership is tested for.
    modifier onlyHolder(bytes32 shard) {
        require(infoByShard[shard].owner == msg.sender);
        _;
    }

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    constructor() {
        // passes full ownership to creator of contract
        _pushShard(Fraction(1,1), msg.sender, block.timestamp);
    }

    /// @notice Puts a given shard for sale.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    function putForSale(bytes32 shard, Fraction memory fraction, address tokenAddress, uint256 price) external onlyHolder(shard) {
        _putForSale(shard,fraction,tokenAddress,price);
    }

    /// @notice Puts a given shard for sale only to a specifically set buyer.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale.
    function putForSaleTo(bytes32 shard, Fraction memory fraction, address tokenAddress, uint256 price, address to) external onlyHolder(shard) {
        _putForSaleTo(shard,fraction,tokenAddress,price,to);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function cancelSale(bytes32 shard) external onlyHolder(shard) {
        _cancelSale(shard);
        emit SaleCancelled(shard);
    }

    /// @notice Purchases a listed Shard for sale.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    /// @param shard The shard of which a fraction will be purchased.
    function purchase(bytes32 shard) external payable onlyIfActive onlyValidShard(shard) {
        require(infoByShard[shard].forSale, "Not for sale");
        require((infoByShard[shard].forSaleTo == msg.sender) || (infoByShard[shard].forSaleTo == address(0x0)), string.concat("Only for sale to ",Strings.toHexString(uint256(uint160(infoByShard[shard].forSaleTo)), 20)));
        _cancelSale(shard);
        (uint256 profitToCounekt, uint256 profitToSeller, uint256 remainder) = divideUnequallyIntoTwoWithRemainder(infoByShard[shard].salePrice,Fraction(25,1000));
        profitToSeller += remainder; // remainder goes to seller
        // if ether
        if (infoByShard[shard].tokenAddress == address(0x0)) {
            require(msg.value >= infoByShard[shard].salePrice, "Not enough ether paid");
            // Pay Service Fee of 2.5% to Counekt
            (bool successCounekt, ) = payable(0x49a71890aea5A751E30e740C504f2E9683f347bC).call{value:profitToCounekt}("");
            require(successCounekt, "Transfer failed.");
            // Rest goes to the seller
            (bool successSeller, ) = payable(infoByShard[shard].owner).call{value:profitToSeller}("");
            require(successSeller, "Transfer failed.");
        } 
        else {
            ERC20 token = ERC20(infoByShard[shard].tokenAddress);
            // Pay Service Fee of 2.5% to Counekt
            token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt);
            // Rest goes to the seller
            token.transferFrom(msg.sender,infoByShard[shard].owner,profitToSeller);
        } 
        if (fractionsAreIdentical(infoByShard[shard].fraction,infoByShard[shard].fractionForSale)) {_transferShard(shard,msg.sender);}
        else {_split(shard, infoByShard[shard].fractionForSale,msg.sender);}
        emit SaleSold(shard,infoByShard[shard].fractionForSale,infoByShard[shard].tokenAddress,infoByShard[shard].salePrice,msg.sender);
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param shard The shard to be split.
    /// @param toBeSplit The absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function split(bytes32 shard, Fraction memory toBeSplit, address to) external onlyHolder(shard) {
        _split(shard, toBeSplit, to);
        emit SplitMade(shard,toBeSplit,to);
    }

    /// @notice Sends a whole shard to a receiver.
    /// @param shard The shard to be transferred.
    /// @param to The receiver of the new Shard.
    function transferShard(bytes32 shard, address to) external onlyHolder(shard) {
        _transferShard(shard,to);
        emit SplitMade(shard,infoByShard[shard].fraction,to);

    }

    /// @notice Returns the information of a unique Shard.
    /// @param shard The shard to get the information on.
    function getShardInfo(bytes32 shard) public view returns(ShardInfo memory) {
        return infoByShard[shard];
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isValidShard(bytes32 shard) public view returns(bool) {
        return currentlyValidShards[shard];
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract.
    /// @param _address The address to be checked for.
    function isShardHolder(address _address) public view returns(bool) {
        return isValidShard(shardByOwner[_address]);
    }

    /// @notice Returns a boolean stating if a given shard has ever been valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isHistoricShard(bytes32 shard) public view returns(bool) {
        return historicallyValidShards[shard];
    }

    /// @notice Checks if address is a historic Shard holder - at least a previous partial owner of the contract
    /// @param _address The address to be checked for.
    function isHistoricShardHolder(address _address) public view returns(bool) {
        return isHistoricShard(shardByOwner[_address]);
    }

    /// @notice Returns a boolean stating if the given shard was valid at a given timestamp.
    /// @param shard The shard, whose validity is to be checked for.
    /// @param time The timestamp to be checked for.
    function shardExisted(bytes32 shard, uint256 time) public view returns(bool) {
        return infoByShard[shard].creationTime <= time && time < infoByShard[shard].expiredTime;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param toBeSplit The absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _split(bytes32 senderShard, Fraction memory toBeSplit, address to) internal {
        require(toBeSplit.numerator/toBeSplit.denominator < infoByShard[senderShard].fraction.numerator/infoByShard[senderShard].fraction.denominator, "Can't split 100% or more of shard's fraction");
        uint256 transferTime = block.timestamp;
        require(transferTime > infoByShard[senderShard].creationTime, "Can't trade more than once per second! The shard to be split must be more than one second old. Wait a second.");
        ShardInfo memory senderShardInfo = infoByShard[senderShard];
        address sender = senderShardInfo.owner;
        bool receiverIsShardHolder = isShardHolder(to);
        Fraction memory newReceiverFraction;

        if (receiverIsShardHolder) { // if Receiver already owns a shard
            bytes32 receiverShard = shardByOwner[to];
            ShardInfo memory receiverShardInfo = infoByShard[receiverShard];
            require(transferTime > receiverShardInfo.creationTime , "Can't trade more than once per second! The receiver's shard must be more than one second old. Wait a second.");

            newReceiverFraction = addFractions(receiverShardInfo.fraction,toBeSplit); // The fractions are added and upgraded
            
            // Expire the Old Receiver Shard
            _expireShard(receiverShard, transferTime); 

        }

        else {
            // The Fraction of the Receiver Shard is equal to the one split off of the Sender Shard
            newReceiverFraction = toBeSplit; 
        }

        // The new Fraction of the Sender Shard has been subtracted by the Split Fraction.
        Fraction memory newSenderFraction = subtractFractions(senderShardInfo.fraction,toBeSplit);

        // Expire the Old Sender Shard
        _expireShard(senderShard, transferTime); 

        // Push the new Shards
        _pushShard(newReceiverFraction,to,transferTime);
        _pushShard(newSenderFraction,sender,transferTime);
    }
    

    /// @notice Sends a whole shard to a receiver.
    /// @param senderShard The shard to be transferred.
    /// @param to The receiver of the new Shard.
    function _transferShard(bytes32 senderShard, address to) internal onlyValidShard(senderShard) {
        uint256 transferTime = block.timestamp;
        Fraction memory newReceiverFraction;
        ShardInfo memory senderShardInfo = infoByShard[senderShard];
        require(transferTime > senderShardInfo.creationTime , "Can't trade more than once per second! The shard must be more than one second old. Wait a second.");

        if (isShardHolder(to)) {
            bytes32 receiverShard = shardByOwner[to];
            ShardInfo memory receiverShardInfo = infoByShard[receiverShard];

            // Destroying the Old receiver
            _expireShard(receiverShard, block.timestamp);

            newReceiverFraction = addFractions(senderShardInfo.fraction,receiverShardInfo.fraction); // The fractions are added and upgraded
        
        }
        else {
            newReceiverFraction = senderShardInfo.fraction;
        }

        // Destroying the Old sender
        _expireShard(senderShard,transferTime);

        // Creating the New
        _pushShard(newReceiverFraction,to,transferTime);
    }

    /// @notice Puts a given shard for sale.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    function _putForSale(bytes32 shard, Fraction memory fraction, address tokenAddress, uint256 price) internal onlyValidShard(shard) onlyIfActive {
        ShardInfo memory shardInfo = infoByShard[shard];
        require(fraction.numerator/fraction.denominator >= shardInfo.fraction.numerator/shardInfo.fraction.denominator, "Can't put more than 100% of shard's fraction for sale!");
        Fraction memory simplifiedFraction = simplifyFraction(fraction);
        shardInfo.fractionForSale = simplifiedFraction;
        shardInfo.tokenAddress = tokenAddress;
        shardInfo.salePrice = price;
        shardInfo.forSale = true;
        emit PutForSale(shard,simplifiedFraction,tokenAddress,price,shardInfo.forSaleTo);
    }

    /// @notice Puts a given shard for sale only to a specifically set buyer.
    /// @param shard The shard to be put for sale.
    /// @param fraction The absolute Fraction of the shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale.
    function _putForSaleTo(bytes32 shard, Fraction memory fraction, address tokenAddress, uint256 price, address to) internal onlyValidShard(shard) onlyIfActive {
        infoByShard[shard].forSaleTo = to;
        _putForSale(shard,fraction,tokenAddress,price);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function _cancelSale(bytes32 shard) internal onlyValidShard(shard) onlyIfActive{
        require(infoByShard[shard].forSale == true, "Shard not even for sale!");
        infoByShard[shard].forSale = false;
        infoByShard[shard].forSaleTo = address(0x0);
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param fraction The fraction of the Shardable that the Shard represents.
    /// @param owner The owner of the Shard.
    /// @param creationTime The block.timestamp at which the Shard will be created.
    function _pushShard(Fraction memory fraction, address owner, uint256 creationTime) internal {
        // The representation, bytes and hash
        bytes32 shard = keccak256(abi.encodePacked(owner,creationTime));
        shardByOwner[owner] = shard;
        currentlyValidShards[shard] = true;
        historicallyValidShards[shard] = true;

        // The info, attributes and details
        ShardInfo memory shardInfo = ShardInfo({
                                fraction: fraction,
                                owner: owner,
                                creationTime: creationTime,
                                expiredTime: type(uint256).max, // The maximum value: (2^256)-1;
                                forSale: false,
                                forSaleTo: address(0x0),
                                fractionForSale: Fraction(0,1),
                                tokenAddress: address(0x0),
                                salePrice: 0});
        infoByShard[shard] = shardInfo;
    }

    /// @notice Removes a shard from the registry of currently valid shards. It will still remain as a historically valid shard.
    /// @param shard The shard to be removed.
    /// @param expiredTime The block.timestamp at which the Shard will expire.
    function _expireShard(bytes32 shard, uint256 expiredTime) internal onlyValidShard(shard) {
        infoByShard[shard].expiredTime = expiredTime;
        currentlyValidShards[shard] = false;
    }

}