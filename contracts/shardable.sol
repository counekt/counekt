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
contract Shardable is ERC20Holder {
    
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

    /// @dev This function creates an unwanted loophole for shardholders to deceively steal more funds than owed from a dividend.
    function splitShard(address to, Fraction toBeSplit) external onlyValidShard {
        Shard shard = msg.sender;
        require(toBeSplit.numerator/toBeSplit.denominator >= shard.fraction.numerator/shard.fraction.denominator, "Can't split more than 100% of shard's fraction");
        
        // if receiver already owns a shard
        if (isShardHolder(to)) { 
            Shard shardToBeUpgraded = shardByOwner[to];
            
            // just add the sold fraction together with the already existing one
            // and subtract that from the shard, which it split off of
            shardToBeUpgraded.changeFraction(addFractions(shardToBeUpgraded.fraction,toBeSplit));
            changeFraction(subtractFractions(fraction,toBeSplit));
            
        }

        else {
            // if the shard to be split is 100% of the shard, which it "split" off of
            if (toBeSplit.numerator/toBeSplit.denominator == shard.fraction.numerator/shard.fraction.denominator) {
                shard.transferOwnership(to); // transfer the whole shard without creating a new one
            }
            else {
                // create a new shard
                Shard new_shard = new Shard(toBeSplit.numerator,toBeSplit.denominator);
                changeFraction(subtractFractions(fraction,toBeSplit)); //subtract that from the shard, which it split off of
                new_shard.transferOwnership(to); // transfer to receiver
                _pushShard(new_shard);
            }
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

    constructor(uint256 _numerator, uint256 _denominator, address holder) ERC721("Shard", "SH") {
        shardable = msg.sender;
        fraction = Fraction(_numerator,_denominator);
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

    function changeFraction(Fraction new_fraction) external onlyShardable {
        if (new_fraction.numerator == 0) {
                shardable.removeShard();
                emit Burned();
                _burn();
        }
        fraction = new Fraction(simplify(new_numerator, new_denominator));
    }

    function transferOwnership(address to) external onlyShardable {
        _transferOwnership(to);
        shardable._processShardTransfer(to);
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