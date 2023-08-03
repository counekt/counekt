// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC721} from "./IERC721.sol";

/// @title A semi-fungible token that represents time-based fractional ownership.
/// @author Frederik W. L. Christoffersen
contract Shardable {
    /// @notice Integer value to implement a concept of time and to distinguish shards by id's.
    uint256 clock;

    /// @notice A struct representing the related info of a non-fungible Shard token.
    /// @dev Is represented via a bytes32 value created from the hash: keccak256(owner, creationClock).
    /// @param amount Amount that the Shard represents.
    /// @param owner The owner of the Shard.
    struct ShardInfo {
        uint256 amount;
        address owner; 
    }

    /// @notice Mapping pointing to integer value representing the total number of shards issued, provided the clock.
    mapping(uint256 => uint256) public totalShardAmountByClock;

    /// @notice Mapping pointing to related info of a Shard given the shardId.
    mapping(uint256 => ShardInfo) public infoByShard;
    
    /// @notice Mapping pointing to a currently valid shardId given the address of its owner.
    mapping(address => uint256) public shardByOwner;
    
    // @notice Mapping pointing to an expiration clock given a shardId.
    mapping(uint256 => uint256) shardExpirationClock;

    mapping(address => mapping(address => uint256)) public allowance;


    /// @notice Event emitted when a Shard is created.
    /// @param status The boolean indicating whether a shard is newly created (true) or expired (false).
    /// @param shardId The Shard byte identifier, which was created.
    event ShardUpdated(
        bool status,
        uint256 shardId
        );

    /// @notice Modifier that requires the msg.sender to be a current valid Shard holder.
    modifier onlyShardHolder {
        require(isShardHolder(msg.sender), "UH");
        _;
    }

    /// @notice Modifier that requires a given Shard to be currently valid.
    modifier onlyValidShard(uint256 shardId) {
        require(isValidShard(shardId), "US");
        _;
    }

    /// @notice Modifier that makes sure the entity is active and not liquidized/dissolved.
    modifier onlyIfActive() {
        require(active == true, "EL");
        _;
    }

    /// @notice Modifier that requires the msg.sender to be the owner of a given Shard
    /// @param shard The Shard, whose ownership is tested for.
    modifier onlyHolder(uint256 shardId) {
        require(infoByShard[shardId].owner == msg.sender, "OH");
        _;
    }

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    /// @param amount Amount of shards to construct Shardable with.
    constructor(uint256 amount) {
        // passes full ownership to creator of contract
        _pushShard(msg.sender,amount);
        totalShardAmountByClock[clock] = amount;
        active = true;
    }

    /// @notice Approves the allowance of a certain amount of the sender's shard to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function approve(address spender, uint256 amount) external returns(bool) {
        require(infoByShard[shardByOwner[msg.sender]].amount >= amount);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param shardId The shard to be split.
    /// @param amount Amount, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function split(uint256 shardId, uint256 amount, address to) public onlyValidShard(senderShard) {
        require(infoByShard[shardId].owner == msg.sender || allowance[infoByShard[shardId].owner][msg.sender] >= amount);
        _split(senderShard,amount,to);
    }

    /// @notice Returns the clock.
    function getCurrentClock() public view returns(uint256) {
        return clock;
    }

    /// @notice Returns the clock, in which a shard will or has expired.
    function getShardExpirationClock(uint256 shardId) public view returns(uint256) {
        return shardExpirationClock[shardId];
    }

    /// @notice Returns the price, at which a shard is for sale.
    function getShardSalePrice(uint256 shardId) public view returns(uint256) {
        return saleByShard[shardId].price;
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param shard The shard, whose validity is to be checked for.
    function isValidShard(uint256 shardId) public view returns(bool) {
        return getShardExpirationClock(shard) > clock;
    }

    /// @notice Checks if address is a shard holder - at least a partial owner of the contract.
    /// @param account The address to be checked for.
    function isShardHolder(address account) public view returns(bool) {
        return isValidShard(shardByOwner[account]);
    }
    
    /// @notice Returns a boolean stating if the given shard was valid at a given clock.
    /// @param shardId The shard, whose validity is to be checked for.
    /// @param atClock The clock to be checked for.
    function shardExisted(uint256 shardId, uint256 atClock) public view returns(bool) {
        return infoByShard[shard].creationClock <= atClock && atClock < getShardExpirationClock(shard);
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param shardId The shard to be split.
    /// @param amount Amount, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _split(uint256 shardId, uint256 amount, address to) internal onlyValidShard(senderShard) onlyIfActive {
        require(amount <= infoByShard[shardId].amount, "IA");
        if (isShardHolder(to)) { // if Receiver already owns a shard
            // The amounts are added and the shard thereby upgraded
            uint256 sumAmount = amount + infoByShard[shardByOwner[to]].amount;
            // Expire the Old Receiver Shard
            _expireShard(shardByOwner[to]);
            _pushShard(to,sumAmount);
        }
        else {
            // The amount of the Receiver Shard is equal to the one split off of the Sender Shard
            _pushShard(to,amount);
        }

        // Expire the Old Sender Shard
        _expireShard(shardId);
        // The new amount of the Sender Shard has been subtracted by the Split amount.
        uint256 diff = infoByShard[shardId].amount - amount;
        if (diff != 0) {
        _pushShard(infoByShard[shardId].owner,diff);
        }
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param owner The owner of the Shard.
    /// @param amount Amount of the Shard represents.
    function _pushShard(address owner,uint256 amount) internal {
        require(amount > 0, "SZ");
        totalShardAmountByClock[clock+1] = totalShardAmountByClock[clock]; // remember the total shard amount at previous clock
        clock++; // increment clock/shardId
        shardByOwner[owner] = clock;
        shardExpirationClock[clock] = type(uint256).max; // The maximum value: (2^256)-1;
        // The info, attributes and details
        infoByShard[clock] = ShardInfo({
                                amount:amount,
                                owner: owner});
        emit ShardUpdated(true,clock);
    }

    /// @notice Removes a shard from the registry of currently valid shards.
    /// @param shard The shard to be expired.
    function _expireShard(uint256 shardId) internal {
        shardExpirationClock[shardId] = clock;
        emit ShardUpdated(false,shardId);
    }

}

contract ShardableBroker {

    /// @notice An enum representing a Sale State of a Shard.
    /// @param notForSale The Shard is NOT for sale.
    /// @param forSale The Shard IS for sale.
    /// @param sold The Shard has been sold.
    enum SaleState {
        notForSale,
        forSale,
        sold
    }

    /// @notice Mapping pointing to an enum stating whether a given Shard isn't, is for sale, or has been sold.
    mapping(address => mapping(uint256 => SaleState)) saleStateByShard;
    
    /// @notice Mapping pointing to related sale info of a Shard given the bytes of a unique Shard instance.
    mapping(address => mapping(uint256 => ShardSale)) saleByShard;

    /// @notice Event emitted when a sale of a Shard is sold.
    /// @param status The enum stating whether the given Shard now isn't, is for sale, or has been sold.
    /// @param shardId The shard whose sale state was updated.
    /// @param sale The sale info reffering to either a listing or a purchase, depending on the status.
    event SaleStateUpdated(
        SaleState status,
        uint256 shardId,
        ShardSale sale
        );

    /// @notice A struct representing the related sale info of a non-fungible Shard token.
    /// @param amount Amount that is for sale.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param to Address pointing to a potentially specifically set buyer of the sale.
    struct ShardSale {
        uint256 amount;
        uint256 price;
        address tokenAddress;
        address to;
    }

    /// @notice Puts a given shard for sale.
    /// @param shardId The shard to be put for sale.
    /// @param amount Amount of the Shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale. Open to anyone, if address(0).
    function putForSale(uint256 shardId, uint256 amount, address tokenAddress, uint256 price, address to) public onlyHolder(shard) onlyValidShard(shard) {
        _putForSale(shard,amount,tokenAddress,price,to);
    }

    /// @notice Cancels a sell of a given shard.
    /// @param shardId The shard to be put off sale.
    function cancelSale(uint256 shardId) public onlyHolder(shard) onlyValidShard(shard) {
        require(saleStateByShard[shardId]==SaleState.forSale, "NS");
        _cancelSale(shard);
    }

    /// @notice Purchases a listed Shard for sale.
    /// @dev If the purchase is with tokens (ie. tokenAddress != 0x0), first call 'token.approve(Shardable.address, salePrice);'
    /// @param shardId The shard of which a fraction will be purchased.
    function purchase(uint256 shardId, uint256 amount, uint256 price) external payable onlyValidShard(shard) {
        require(saleStateByShard[shardId]==SaleState.forSale, "NS");
        require(price == saleByShard[shardId].price, "WP");
        require(amount != 0, "ES");
        require(saleByShard[shardId].amount >= amount, "ES");
        require((saleByShard[shardId].to == msg.sender) || (saleByShard[shard].to == address(0x0)), "SR");
        saleStateByShard[shardId] = SaleState.sold; // shard has been sold
        uint256 totalPrice = amount * saleByShard[shardId].price;
        (uint256 profitToCounekt, uint256 profitToSeller, uint256 remainder) = divideUnequallyIntoTwoWithRemainder(totalPrice,25,1000);
        profitToSeller += remainder; // remainder goes to seller
        // if ether
        if (saleByShard[shardId].tokenAddress == address(0x0)) {
            require(msg.value >= totalPrice, "IE");
            // Pay Service Fee of 2.5% to Counekt
            (bool successToCounekt,) = payable(0x49a71890aea5A751E30e740C504f2E9683f347bC).call{value:profitToCounekt}("");
            // Rest goes to the seller
            (bool successToSeller,) = payable(infoByShard[shardId].owner).call{value:profitToSeller}("");
            require(successToSeller && successToCounekt, "TF");
        }
        else {
            ERC20 token = ERC20(saleByShard[shardId].tokenAddress);
            require(token.allowance(msg.sender,address(this)) >= totalPrice,"IT");
            // Pay Service Fee of 2.5% to Counekt
            require(token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt), "NT");
            // Rest goes to the seller
            if (infoByShard[shardId].owner.code.length > 0) {
                token.approve(infoByShard[shardId].owner,profitToSeller);
                infoByShard[shardId].owner.receiveToken(tokenAddress,profitToSeller);
            }
            else {token.transferFrom(msg.sender,infoByShard[shardId].owner,profitToSeller);}
        }
        _split(shardId, amount,msg.sender);
        if (infoByShard[shardId].owner == address(this)) { // if newly issued shards
            // add those to the outstanding shard amount
            totalShardAmountByClock[clock] += amount;
        }
        emit SaleStateUpdated(SaleState.sold,shard,ShardSale(amount,saleByShard[shardId].price,saleByShard[shardId].tokenAddress,saleByShard[shardId].to));
        // if not whole shard is bought
        if (saleByShard[shardId].amount != amount) { 
            // put the rest to sale again
            _putForSale(shardByOwner[infoByShard[shardId].owner],saleByShard[shardId].amount-amount,saleByShard[shardId].tokenAddress,saleByShard[shardId].price,saleByShard[shardId].to);
        }
    }

    /// @notice Cancels a sell of a given Shard.
    /// @param shard The shard to be put off sale.
    function _cancelSale(uint256 shardId) internal onlyValidShard(shard) {
        saleStateByShard[shard] = SaleState.notForSale;
        emit SaleStateUpdated(SaleState.notForSale,shard,ShardSale(0,0,address(0),address(0)));
    }


    /// @notice Puts a given shard for sale.
    /// @param shardId The shard to be put for sale.
    /// @param amount Amount of the Shard to be put for sale.
    /// @param tokenAddress The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale. For anyone to buy if address(0).
    function _putForSale(uint256 shardId, uint256 amount, address tokenAddress, uint256 price, address to) internal onlyValidShard(shard) onlyIfActive {
        require(saleStateByShard[shardId]==SaleState.notForSale);
        require(amount <= infoByShard[shardId].amount, "IA");
        saleByShard[shardId] = ShardSale({
            amount: amount,
            price: price,
            tokenAddress: tokenAddress,
            to: to
        });
        saleStateByShard[shardId] = SaleState.forSale;
        emit SaleStateUpdated(SaleState.forSale,shardId,saleByShard[shardId]);
    }
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