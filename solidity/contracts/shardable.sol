// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Returns a boolean stating if two given fractions are identical.
/// @param numerator1 Numerator of first fraction.
/// @param denominator1 Denominator of first fraction.
/// @param numerator2 Numerator of second fraction.
/// @param denominator2 Denominator of second fraction.
function fractionsAreIdentical(uint256 numerator1, uint256  denominator1, uint256 numerator2, uint256 denominator2) pure returns(bool) {
    return numerator1 == numerator2 && denominator1 == denominator2;
}

/// @notice Returns the two quotients and the remainder of an uneven division with a fraction. Useful for dividing ether and tokens.
/// @param dividend The dividend, which will be divided by the fraction.
/// @param numerator Numerator of fraction, which the dividend will be divided into.
/// @param denominator Denominator of fraction, which the dividend will be divided into.
function divideUnequallyIntoTwoWithRemainder(uint256 dividend, uint256 numerator, uint256 denominator) pure returns(uint256, uint256, uint256) {
    require(denominator > numerator);
    uint256 quotient1 = dividend*numerator/denominator;
    uint256 quotient2 = dividend*(denominator-numerator)/denominator;
    return (quotient1, quotient2, dividend - (quotient1 + quotient2));
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
/// @param numerator Numerator of fraction to be simplified.
/// @param denominator Denominator of fraction to be simplified.
function simplifyFraction(uint256 numerator, uint256 denominator) pure returns(uint256, uint256) {
    uint256 commonDenominator = getCommonDenominator(numerator,denominator);
    require(numerator/denominator == ((numerator/commonDenominator)/(denominator/commonDenominator)),"VMT");
    return (numerator/commonDenominator,denominator/commonDenominator);
}

/// @notice Adds two fractions together.
/// @param numerator1 Numerator of first fraction.
/// @param denominator1 Denominator of first fraction.
/// @param numerator2 Numerator of second fraction.
/// @param denominator2 Denominator of second fraction.
function addFractions(uint256 numerator1, uint256  denominator1, uint256 numerator2, uint256 denominator2) pure returns (uint256, uint256) {
    numerator1 = numerator1 * denominator2;
    numerator2 = numerator2 * denominator1;
    return (numerator1+numerator2,denominator1*denominator2);
}

/// @notice Subtracts a fraction from another and returns the difference.
/// @param numerator1 Numerator of minuend fraction.
/// @param denominator1 Denominator of minuend fraction.
/// @param numerator2 Numerator of subtrahend fraction.
/// @param denominator2 Denominator of subtrahend fraction.
function subtractFractions(uint256 numerator1, uint256 numerator2, uint256  denominator1, uint256 denominator2) pure returns (uint256,uint256) {
    numerator1 = numerator1 * denominator2;
    numerator2 = numerator2 * denominator1;
    return (numerator1-numerator2,denominator1*denominator2);
}


/// @title A shardable/fractional non-fungible token that can be fractually owned via Shards.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used to fractionalize a non-fungible token. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev historicShards are used to show proof of ownership at different points of time.
/// @custom:beaware This is a commercial contract.
contract Shardable {

    /// @notice A struct representing the related info of a non-fungible Shard token.
    /// @dev Is represented via a bytes32 value created from the hash: keccak256(owner, creationTime).
    /// @param numerator Numerator of the fraction that the Shard represents.
    /// @param denominator Denominator of the fraction that the Shard represents.
    /// @param owner The owner of the Shard.
    /// @param creationTime The clock at which the Shard was created.
    /// @param expiredTime The clock at which the Shard expired. Default is set to the maximum value.
    struct ShardInfo {
        uint256 numerator;
        uint256 denominator;
        address owner; 
        uint256 creationTime;        
    }

    /// @notice A struct representing the related sale info of a non-fungible Shard token.
    /// @param numerator Numerator of the fraction that is for sale.
    /// @param denominator Denominator of the fraction that is for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to Address pointing to a potentially specifically set buyer of the sale.
    struct ShardSale {
        uint256 numerator;
        uint256 denominator;
        address tokenAddress;
        uint256 price;
        address to;

    }

    /// @notice Integer value to implement a concept of time
    uint256 clock = 0;

    /// @notice Boolean stating if the Shardable is active and tradeable or not.
    bool public active;
    /// @notice Mapping pointing to related info of a Shard given the bytes of a unique Shard instance.
    mapping(bytes32 => ShardInfo) public infoByShard;
    /// @notice Mapping pointing to a currently valid shard given the address of its owner.
    mapping(address => bytes32) public shardByOwner;
    /// @notice Mapping pointing to a boolean stating if a given Shard is for sale or not.
    mapping(bytes32 => bool) shardsForSale;
    /// @notice Mapping pointing to related sale info of a Shard given the bytes of a unique Shard instance.
    mapping(bytes32 => ShardSale) saleByShard;
    // @notice Mapping pointing to an expired time given a shard.
    mapping(bytes32 => uint256) shardExpiredTime;
    
    /// @notice Event emitted when a Shard is split into two and fractionally transferred.
    /// @param shard The Shard, which was split.
    /// @param numerator Numerator of the absolute fraction of the offspring Shard.
    /// @param denominator Denominator of the absolute fraction of the offspring Shard.
    /// @param to The receiver of the splitted Shard.
    event SplitMade(
        bytes32 shard,
        uint256 numerator,
        uint256 denominator,
        address to
        );

    /// @notice Event emitted when a sale of a Shard is sold.
    /// @param shard The shard that was sold from.
    /// @param numerator Numerator of the absolute fraction of the Shard that was sold.
    /// @param denominator Denominator of the absolute fraction of the Shard that was sold.
    /// @param tokenAddress The address of the token that was accepted in the purchase. A value of 0x0 represents ether.
    /// @param price The amount which the Shard was for sale for. The token address being the valuta.
    /// @param to The buyer of the sale.
    event SaleSold(
        bytes32 shard,
        uint256 numerator,
        uint256 denominator,
        address tokenAddress,
        uint256 price,
        address to
        );

    /// @notice Event emitted when a Shard is put up for sale.
    /// @param shard The shard that was put for sale.
    /// @param numerator Numerator of the absolute fraction of the Shard put for sale.
    /// @param denominator Denominator of the absolute fraction of the Shard put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale, if any.
    event PutForSale(
        bytes32 shard,
        uint256 numerator,
        uint256 denominator,
        address tokenAddress,
        uint256 price,
        address to
        );

    modifier incrementClock {
        _;
        clock++;
    }
    
    /// @notice Modifier that requires the msg.sender to be a current valid Shard holder.
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "UH");
        _;
    }

    /// @notice Modifier that requires a given Shard to be currently valid.
    modifier onlyValidShard(bytes32 shard) {
        require(isValidShard(shard), "US");
        _;
    }

    /// @notice Modifier that makes sure the entity is active and not liquidized/dissolved.
    modifier onlyIfActive() {
        require(active == true, "EL");
        _;
    }

    /// @notice Modifier that requires the msg.sender to be the owner of a given Shard
    /// @param shard The Shard, whose ownership is tested for.
    modifier onlyHolder(bytes32 shard) {
        require(infoByShard[shard].owner == msg.sender, "OH");
        _;
    }

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    constructor() {
        // passes full ownership to creator of contract
        _pushShard(1, 1, msg.sender, 0);
        active = true;
    }

    /// @notice Purchases a listed Shard for sale.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    /// @param shard The shard of which a fraction will be purchased.
    function purchase(bytes32 shard) external payable onlyValidShard(shard) {
        require(shardsForSale[shard], "NS");
        require((saleByShard[shard].to == msg.sender) || (saleByShard[shard].to == address(0x0)), "SR");
        _cancelSale(shard);
        (uint256 profitToCounekt, uint256 profitToSeller, uint256 remainder) = divideUnequallyIntoTwoWithRemainder(saleByShard[shard].price,25,1000);
        profitToSeller += remainder; // remainder goes to seller
        // if ether
        if (saleByShard[shard].tokenAddress == address(0x0)) {
            require(msg.value >= saleByShard[shard].price, "IE");
            // Pay Service Fee of 2.5% to Counekt
            (bool successToCounekt,) = payable(0x49a71890aea5A751E30e740C504f2E9683f347bC).call{value:profitToCounekt}("");
            // Rest goes to the seller
            (bool successToSeller,) = payable(infoByShard[shard].owner).call{value:profitToSeller}("");
            require(successToSeller && successToCounekt, "TF");
        } 
        else {
            ERC20 token = ERC20(saleByShard[shard].tokenAddress);
            require(token.allowance(msg.sender,address(this)) >= saleByShard[shard].price,"IT");
            // Pay Service Fee of 2.5% to Counekt
            token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt);
            // Rest goes to the seller
            token.transferFrom(msg.sender,infoByShard[shard].owner,profitToSeller);
        } 
        require(saleByShard[shard].numerator != 0 && saleByShard[shard].denominator != 0, "ES");
        if (fractionsAreIdentical(infoByShard[shard].numerator,infoByShard[shard].denominator,saleByShard[shard].numerator,saleByShard[shard].denominator)) {_transferShard(shard,msg.sender);}
        else {_split(shard, saleByShard[shard].numerator,saleByShard[shard].denominator,msg.sender);}
        emit SaleSold(shard,saleByShard[shard].numerator,saleByShard[shard].denominator,saleByShard[shard].tokenAddress,saleByShard[shard].price,msg.sender);
    }

    /// @notice Puts a given shard for sale.
    /// @param shard The shard to be put for sale.
    /// @param numerator Numerator of the absolute fraction of the Shard to be put for sale.
    /// @param denominator Denominator of the absolute fraction of the Shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale. Open to anyone, if address(0).
    function putForSale(bytes32 shard, uint256 numerator, uint256 denominator, address tokenAddress, uint256 price, address to) public onlyHolder(shard) onlyValidShard(shard) {
        _putForSale(shard,numerator,denominator,tokenAddress,price,to);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function cancelSale(bytes32 shard) public onlyHolder(shard) onlyValidShard(shard) {
        require(shardsForSale[shard], "NS");
        _cancelSale(shard);
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param numerator Numerator of the absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param denominator Denominator of the absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function split(bytes32 senderShard, uint256 numerator, uint256 denominator, address to) public onlyHolder(senderShard) onlyValidShard(senderShard) {
        _split(senderShard,numerator,denominator,to);
    }

    /// @notice Sends a whole shard to a receiver.
    /// @param senderShard The shard to be transferred.
    /// @param to The receiver of the new Shard.
    function transferShard(bytes32 senderShard, address to) public onlyHolder(senderShard) onlyValidShard(senderShard) {
        _transferShard(senderShard,to);
    }

    /// @notice Returns the time, in which a shard will or has expired.
    function getShardExpiredTime(bytes32 shard) public view returns(uint256) {
        return shardExpiredTime[shard];
    }

    /// @notice Returns the price, at which a shard is for sale.
    function getShardSalePrice(bytes32 shard) public view returns(uint256) {
        return saleByShard[shard].price;
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isValidShard(bytes32 shard) public view returns(bool) {
        return getShardExpiredTime(shard) > clock;
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract.
    /// @param account The address to be checked for.
    function isShardHolder(address account) public view returns(bool) {
        return isValidShard(shardByOwner[account]);
    }
    
    /// @notice Returns a boolean stating if the given shard was valid at a given timestamp.
    /// @param shard The shard, whose validity is to be checked for.
    /// @param time The timestamp to be checked for.
    function shardExisted(bytes32 shard, uint256 time) public view returns(bool) {
        return infoByShard[shard].creationTime <= time && time < getShardExpiredTime(shard);
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function _cancelSale(bytes32 shard) internal onlyValidShard(shard) {
        shardsForSale[shard] = false;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param senderShard The shard to be split.
    /// @param numerator Numerator of the absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param denominator Denominator of the absolute fraction, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _split(bytes32 senderShard, uint256 numerator, uint256 denominator, address to) internal onlyValidShard(senderShard) onlyIfActive incrementClock {
        require(numerator/denominator < infoByShard[senderShard].numerator/infoByShard[senderShard].denominator, "IF");
        uint256 transferTime = clock;
        if (isShardHolder(to)) { // if Receiver already owns a shard
            // The fractions are added and upgraded
            (uint256 sumNumerator, uint256 sumDenominator) = addFractions(infoByShard[shardByOwner[to]].numerator,infoByShard[shardByOwner[to]].denominator,numerator,denominator);
            _pushShard(sumNumerator,sumDenominator,to,transferTime);

            // Expire the Old Receiver Shard
            _expireShard(shardByOwner[to], transferTime);

        }

        else {
            // The Fraction of the Receiver Shard is equal to the one split off of the Sender Shard
            _pushShard(numerator,denominator,to,transferTime);
        }


        // Expire the Old Sender Shard
        _expireShard(senderShard, transferTime);
        // The new Fraction of the Sender Shard has been subtracted by the Split Fraction.
        (uint256 diffNumerator, uint256 diffDenominator) = subtractFractions(infoByShard[senderShard].numerator,infoByShard[senderShard].denominator,numerator,denominator);
        _pushShard(diffNumerator,diffDenominator,infoByShard[senderShard].owner,transferTime);
        if (msg.sender != address(this)) {
            emit SplitMade(senderShard,numerator,denominator,to);
        }
        
    }

    /// @notice Sends a whole shard to a receiver.
    /// @param senderShard The shard to be transferred.
    /// @param to The receiver of the new Shard.
    function _transferShard(bytes32 senderShard, address to) internal onlyValidShard(senderShard) onlyIfActive incrementClock {
        uint256 transferTime = clock;
        if (isShardHolder(to)) {

            // Destroying the Old receiver
            _expireShard(shardByOwner[to], transferTime);

            // The fractions are added and upgraded,to,transferTime
            (uint256 numerator, uint256 denominator) = addFractions(infoByShard[senderShard].numerator,infoByShard[senderShard].denominator,infoByShard[shardByOwner[to]].numerator,infoByShard[shardByOwner[to]].denominator);
            _pushShard(numerator,denominator,to,transferTime);
        }
        else {
            _pushShard(infoByShard[senderShard].numerator,infoByShard[senderShard].denominator,to,transferTime);
        }

        // Destroying the Old sender
        _expireShard(senderShard, transferTime);
        
        if (msg.sender != address(this)) {
            emit SplitMade(senderShard,infoByShard[senderShard].numerator,infoByShard[senderShard].numerator,to);
        }
    }

    /// @notice Puts a given shard for sale.
    /// @param shard The shard to be put for sale.
    /// @param numerator Numerator of the absolute fraction of the Shard to be put for sale.
    /// @param denominator Denominator of the absolute fraction of the Shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale. For anyone to buy if address(0).
    function _putForSale(bytes32 shard, uint256 numerator, uint256 denominator, address tokenAddress, uint256 price, address to) internal onlyValidShard(shard) onlyIfActive {
        require(numerator/denominator <= infoByShard[shard].numerator/infoByShard[shard].denominator, "IF");
        (numerator, denominator) = simplifyFraction(numerator,denominator);
        saleByShard[shard] = ShardSale({
            numerator: numerator,
            denominator: denominator,
            tokenAddress: tokenAddress,
            price: price,
            to: to
        });
        shardsForSale[shard] = true;
        emit PutForSale(shard,numerator,denominator,tokenAddress,price,to);
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param numerator Numerator of the fraction that the Shard represents.
    /// @param denominator Denominator of the fraction that the Shard represents.
    /// @param owner The owner of the Shard.
    /// @param creationTime The clock at which the Shard will be created.
    function _pushShard(uint256 numerator, uint256 denominator, address owner, uint256 creationTime) internal {
        // The representation, bytes and hash
        bytes32 shard = keccak256(abi.encodePacked(owner,creationTime));
        shardByOwner[owner] = shard;
        shardExpiredTime[shard] = type(uint256).max; // The maximum value: (2^256)-1;
        // The info, attributes and details
        infoByShard[shard] = ShardInfo({
                                numerator:numerator,
                                denominator:denominator,
                                owner: owner,
                                creationTime: creationTime
                                });
    }

    /// @notice Removes a shard from the registry of currently valid shards.
    /// @param shard The shard to be expired.
    /// @param expiredTime The clock at which the Shard will expire.
    function _expireShard(bytes32 shard, uint256 expiredTime) internal  {
        shardExpiredTime[shard] = expiredTime;
    }

}