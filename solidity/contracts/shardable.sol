// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
contract ERC360Broker {

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
    /// @param tokenId The shard whose sale state was updated.
    /// @param sale The sale info reffering to either a listing or a purchase, depending on the status.
    event SaleStateUpdated(
        SaleState status,
        uint256 tokenId,
        ShardSale sale
        );

    /// @notice A struct representing the related sale info of a non-fungible Shard token.
    /// @param amount Amount that is for sale.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param token The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param to Address pointing to a potentially specifically set buyer of the sale.
    struct ShardSale {
        uint256 amount;
        uint256 price;
        address token;
        address to;
    }

    /// @notice Puts a given shard for sale.
    /// @param shardId The shard to be put for sale.
    /// @param amount Amount of the Shard to be put for sale.
    /// @param token The address of the token that is accepted when purchasing. A value of 0x0 represents ether.
    /// @param price The amount which the Shard is for sale as. The token address being the valuta.
    /// @param to The specifically set buyer of the sale. Open to anyone, if address(0).
    function putForSale(uint256 amount, address token, uint256 price, address to) public onlyHolder(shard) onlyValidShard(shard) {
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
            IERC20 token = IERC20(saleByShard[shardId].tokenAddress);
            require(token.allowance(msg.sender,address(this)) >= totalPrice,"IT");
            // Pay Service Fee of 2.5% to Counekt
            require(token.transferFrom(msg.sender, 0x49a71890aea5A751E30e740C504f2E9683f347bC, profitToCounekt), "NT");
            // Rest goes to the seller
            if (infoByShard[shardId].owner.code.length > 0) {
                token.transferFrom(msg.sender, address(this), profitToSeller);
                token.approve(infoByShard[shardId].owner,profitToSeller);
                infoByShard[shardId].owner.receiveToken(tokenAddress,profitToSeller);
            }
            else {token.transferFrom(msg.sender,infoByShard[shardId].owner,profitToSeller);}
        }
        _split(shardId, amount,msg.sender);
        if (infoByShard[shardId].owner == address(this)) { // if newly issued shards
            // add those to the outstanding shard amount
            totalSupplyByClock[clock] += amount;
        }
        emit SaleStateUpdated(SaleState.sold,shard,ShardSale(amount,saleByShard[shardId].price,saleByShard[shardId].tokenAddress,saleByShard[shardId].to));
        // if not whole shard is bought
        if (saleByShard[shardId].amount != amount) { 
            // put the rest to sale again
            _putForSale(currentShardIdByOwner[infoByShard[shardId].owner],saleByShard[shardId].amount-amount,saleByShard[shardId].tokenAddress,saleByShard[shardId].price,saleByShard[shardId].to);
        }
    }

    /// @notice Returns the price, at which a shard is for sale.
    function getShardSalePrice(uint256 shardId) public view returns(uint256) {
        return saleByShard[shardId].price;
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
*/