pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";

// the contract, which can be fractually owned via Shards

contract Shardable is ERC20Holder {
    
    Shard[] public shards;
    mapping(address => Shard);

    constructor() public {
        // pass full ownership to creator of contract
        shards.push(new Shard(1,1, msg.sender));
    }

    modifier onlyShardHolder {
        require(isShardHolder(msg.sender));
    }

    function isShardHolder(address _shardHolder) returns(bool) {
        bool memory _isShardHolder = false;
        for (uint256 i = 0; i < shards.length; i++) {
            if (_shardHolder.ownerOf(shards[i])) {
                _isShardHolder = true;
            }
        }
        return _isShardHolder;
    }

    function getShardHolders() public view returns(address [] memory){
        address[] memory shardHolders;
        for (uint256 i = 0; i < shards.length; i++) {
            shardHolders.push(shards[i].owner())
        }
        return shardHolders;
    }

    function getShardByHolder(address _shardHolder) public view returns(address memory) {
        for (uint256 i = 0; i < shards.length; i++) {
            if (_shardHolder.ownerOf(shards[i])) {
                return shards[i];
            }   
        }
    }

}


contract Shard is ERC721, ERC721Burnable, Ownable {
    Shardable public shardable;
    bool public forSale = false;
    address public forSaleTo;
    uint256 public salePrice;

    struct Fraction {
        uint256 public numerator;
        uint256 public denominator;
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

    event SplitMade(
        address from,
        address to,
        uint256 numerator,
        uint256 denominator
        );

    event SaleSold(
        address from,
        address indexed to,
        uint256 numerator,
        uint256 denominator,
        uint256 price
        );

    event PutForSale(
        address from,
        address indexed to,
        uint256 numerator,
        uint256 denominator,
        uint256 price
        );

    event SaleCancelled();

    event Burned(
        Shardable shardable,
        address holder
        );

    function getCommonDenominator(uint256 a, uint256 b) internal pure returns(uint256) {
        while (b) {
        a,b = b, a % b
        }
        return a;
    }

    function simplifyFraction(Fraction _fraction) internal pure returns(Fraction) {
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


    function putForSaleTo(address to, uint256 price, uint256 _numerator, uint256 _denominator) external onlyOwner {
        forSaleTo = to;
        putForSale(price,_numerator,_denominator);
    }

    function putForSale(uint256 price, uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(_numerator/_denominator >= fraction.numerator/fraction.denominator, "Can't put for sale more than shard's fraction");
        fractionForsale = Fraction(simplify(_numerator, _denominator));
        salePrice = price;
        forsale = True;
        emit PutForSale(forSaleTo,_numerator,_denominator,price);
    }

    function _cancelSell() internal private {
        forSale = false;
        forSaleTo = null;
    }

    function cancelSell() onlyOwner {
        _cancelSell();
        emit SellCancelled();
    }

    function purchase() external payable {
        require(forsale, "Not for sale");
        require(forSaleTo == msg.sender.address || !forSaleTo, string.concat("Only for sale to "+string(address)))
        require(msg.value >= salePrice, "Not enough paid");
        _cancelSell();
        // Pay Service Fee of 2.5% to Counekt
        (bool success, ) = address(0x49a71890aea5A751E30e740C504f2E9683f347bC).call.value(msg.value*0.025)("");
        require(success, "Transfer failed.");
        _split(to: msg.sender.address, _numerator: fractionForsale.numerator, _denominator: fractionForsale.denominator);
        emit SaleSold(to: msg.sender.address, numerator: fractionForsale.numerator, denominator: fractionForsale.denominator, price: salePrice);
    }

    function _split(address to, uint256 _numerator, uint256 _denominator) private internal {
        require(_numerator/_denominator >= fraction.numerator/fraction.denominator, "Can't split more than shard's fraction");
        uint256 _fraction = simplifyFraction(_numerator,_denominator);

        // if receiver already owns a shard
        if (shardable.isShardHolder(to)) { 
            Shard shardToBeUpgraded = shardable.getShardByHolder(to);
            
            // just add the sold fraction together with the already existing one
            // and subtract that from the shard, which it split off of
            shardToBeUpgraded.changeFraction(addFractions(shardToBeUpgraded.fraction,_fraction));
            changeFraction(subtractFractions(fraction,_fraction));
            
        }

        else {
            // if the shard to be split is equal to the fraction of the shard, which it split off of
            if (_fraction.numerator/fraction._denominator == fraction.numerator/fraction.denominator) {
                _transferOwnership(holder); // transfer the whole shard without creating a new one
            }
            else {
                // create a new shard
                Shard new_shard = new Shard(_fraction.numerator,_fraction.denominator);
                changeFraction(subtractFractions(fraction,_fraction)); //subtract that from the shard, which it split off of
                new_shard.transferOwnership(to); // transfer to receiver
            }
        }

    }

    function split(address to, uint256 _numerator, uint256 _denominator) external onlyOwner {
        _split(to,_numerator,_denominator);
        emit SplitMade(to,_numerator,_denominator);
    }

    function changeFraction(Fraction new_fraction) external onlyShardable {
        if (new_fraction.numerator == 0) {
                emit Burned()
                _burn();
        }
        fraction = new Fraction(simplify(new_numerator, new_denominator));
    }

    function _burn() private internal {
        super._burn();
    }

    
}