import "IERC360.sol";

/// @title A semi-fungible token that represents time-based fractional ownership.
/// @author Frederik W. L. Christoffersen
contract ERC360 is Context, ERC165, IERC360, IERC360Metadata, IERC360Errors {
    using Counters for Counters.Counter;

    /// @notice Integer value to implement a concept of time and to distinguish tokens by id's.
    Counters.Counters tokenClock;

    /// @notice A struct representing the related info of a semi-fungible Shard token.
    /// @param amount Amount that the token represents.
    /// @param owner The owner of the token.
    struct TokenInfo {
        uint256 amount;
        address owner; 
    }

    /// @notice Mapping pointing to integer value representing the total amount of tokens on the market, provided the clock.
    mapping(uint256 => uint256) totalSupplyByClock;
    
    /// @notice Mapping pointing to a currently valid shardId given the address of its owner.
    mapping(address => uint256) currentTokenIdByOwner;
    
    /// @notice Mapping pointing to related info of a token given the tokenId.
    mapping(uint256 => TokenInfo) infoByTokenId;

    // @notice Mapping pointing to an expiration clock given a shardId.
    mapping(uint256 => uint256) expirationByTokenId;

    mapping(address => mapping(address => uint256)) public allowance;


    /// @notice Event emitted when a new token is minted.
    /// @param owner The owner of the new token.
    /// @param tokenId The id of the token.
    event NewTokenId(
        address owner,
        uint256 tokenId
        );

    /// @notice Constructor function that pushes the first Shard being the property of the Shardable creator.
    /// @param amount Amount of shards to construct Shardable with.
    constructor(uint256 amount) {
        // passes full ownership to creator of contract
        _mint(_msgSender(),amount);
        totalSupplyByClock[currentClock()] = amount;
    }

    /// @notice Approves the allowance of a certain amount of the sender's shard to a spender
    /// @param spender The spender of the approved amount.
    /// @param amount The amount to be approved to be spent by the spender.
    function approve(address spender, uint256 amount) external returns(bool) {
        require(balanceOf(_msgSender()) >= amount);
        allowance[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return infoByTokenId[tokenId].owner;
    }

    function amountOf(uint256 tokenId) public view virtual returns (uint256) {
        return infoByTokenId[tokenId].amount;
    }

    function tokenOf(address account) public view virtual returns (uint256) {
        return currentTokenIdByOwner[account]; // if 0, account has never been owner of this token before
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return amountOf(tokenOf(account));
    }

    /// @notice Returns the clock.
    function currentClock() public view returns(uint256) {
        return tokenClock.current();
    }

    /// @notice Returns the clock.
    function totalSupply() public view returns(uint256) {
        return totalSupplyByClock[currentClock()];
    }

    /// @notice Returns the clock, in which a shard will or has expired.
    function expirationOf(uint256 tokenId) public view returns(uint256) {
        return expirationByTokenId[tokenId] || type(uint256).max;
    }

    /// @notice Returns a boolean stating if a given shard is currently valid or not.
    /// @param tokenId The shard, whose validity is to be checked for.
    function isValid(uint256 tokenId) public view returns(bool) {
        return currentClock() < expirationOf(tokenId);
    }
    
    /// @notice Returns a boolean stating if the given tokenId was current at a given clock.
    /// @param tokenId The token whose validity is to be checked for.
    /// @param clock The token clock to be checked for.
    function wasValid(uint256 tokenId, uint256 clock) public view returns(bool) {
        return tokenId <= clock && clock < expirationOf(tokenId);
    }

    /// @notice Splits a currently valid shard into two new ones. One is assigned to the receiver. The rest to the previous owner.
    /// @param shardId The shard to be split.
    /// @param amount Amount, which will be subtracted from the previous shard and sent to the receiver.
    /// @param to The receiver of the new Shard.
    function _transfer(address from, address to, uint256 amount) internal {
        require(amount <= balanceOf(from), "IA");
        // The amounts are added and the tokens thereby updated
        _update(from,balanceOf(from) - amount);
        _update(to,balanceOf(to) + amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {revert ERC360InvalidReceiver(address(0));}
        _update(_msgSender(),amount);
        totalSupplyByClock[currentClock()] += amount;
    }

    /// @notice Pushes a shard to the registry of currently valid shards.
    /// @param owner The owner of the Shard.
    /// @param amount Amount of the Shard represents.
    function _update(address owner,uint256 amount) internal {
        expirationByTokenId[tokenOf(owner)] = currentClock(); // Expire the old token
        totalSupplyByClock[currentClock()+1] = totalSupplyByClock[currentClock()]; // forward the total supply to next clock/tokenId
        tokenClock.increment(); // increment clock/tokenId
        currentTokenIdByOwner[owner] = currentClock();
        // The info, attributes and details
        infoByTokenId[currentClock()] = TokenInfo({
                                amount:amount,
                                owner: owner});
        emit NewTokenId(owner,currentClock());
    }

}
