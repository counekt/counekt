// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./idea.sol";

/// @title An extension of the Idea providing an administrable interface.
/// @author Frederik W. L. Christoffersen
/// @notice This contract adds administrability via permits and internally closed money supplies.
contract Administrable is Idea {

    /// @notice An enum representing a Permit State of one of the many permits.
    /// @param unauthorized The permit is NOT authorized.
    /// @param authorized The permit is authorized.
    /// @param administrator The holder of the permit is not only authorized but also an administrator of it too.
    enum PermitState {
        unauthorized,
        authorized,
        administrator
    }

    /// @notice A struct representing the information of a Dividend given to all current Shard holders.
    /// @param tokenAddress The address of the token, in which the value of the Dividend is issued.
    /// @param value The original value/amount of the Dividend before claims.
    struct DividendInfo {
        address tokenAddress;
        uint256 value;
    }

    /// @notice A boolean stating if Non Shard Holders are allowed to administer the administrable or not.
    bool allowNonShardHolders;

    /// @notice A mapping pointing to a boolean stating if a given Bank is valid/exists or not.
    mapping(string => bool) validBanks;
    
    /// @notice A mapping pointing to an unsigned integer representing the amount of stored kinds of tokens of a bank.
    mapping(string => uint256) storedTokenAddressesByBank;

    /// @notice A mapping pointing to the a value/amount of a stored token of a Bank, given the name of it and the respective token address.
    mapping(string => mapping(address => uint256)) balanceByBank;

     /// @notice A mapping pointing to a boolean stating if an address is an if a given address is a valid Bank administrator that has restricted control of the Bank's funds.
    mapping(string => mapping(address => bool)) adminOfBank;

    /// @notice A mapping pointing to another mapping, pointing to a Permit State, given the address of a permit holder, given the name of the permit.
    /// @custom:illustration permits[permitName][address] == PermitState.authorized || PermitState.administrator;
    mapping(string => mapping(address => PermitState)) permits;

    /// @notice A mapping pointing to a base Permit State, given the name of the permit.
    mapping(string => PermitState) basePermits;
    
    /// @notice A mapping pointing to a boolean stating if a given Dividend is valid or not.
    mapping(uint256 => bool) validDividends;

    /// @notice A mapping pointing to the info of a Dividend given the creation clock of the Dividend.
    mapping(uint256 => DividendInfo) infoByDividend;

    /// @notice A mapping pointing to the residual of a Dividend given the creation clock of the Dividend.
    mapping(uint256 => uint256) residualByDividend;

    /// @notice Mapping pointing to a boolean stating if the owner of a Shard has claimed their fair share of the Dividend, given the bank name and the shard.
    mapping(uint256 => mapping(bytes32  => bool)) hasClaimedDividend;

    /// @notice Event that triggers when an action is taken by somebody.
    /// @param func The name of the function that was called.
    /// @param args The arguments passed to the function call.
    /// @param by The initiator of the action.
    event ActionTaken(
        string func,
        bytes args,
        address by
        );

    /// @notice Modifier that makes sure msg.sender has a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyWithPermit(string memory permitName) {
        require(hasPermit(permitName, msg.sender));
        _;
    }
    
    /// @notice Modifier that makes sure msg.sender is an admin of a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyPermitAdmin(string memory permitName) {
        require(isPermitAdmin(permitName, msg.sender));
        _;

    }

    /// @notice Modifier that makes sure msg.sender is admin of a given bank.
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyBankAdmin(string memory bankName) {
        require(isBankAdmin(bankName, msg.sender));
        _;
    }

    /// @notice Modifier that makes sure a given bank exists
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyExistingBank(string memory bankName) {
        require(bankExists(bankName), "DNE");
        _;
    }
    
    /// @notice Modifier that makes sure a given dividend exists and is valid
    /// @param dividend The Dividend to be checked for.
    modifier onlyExistingDividend(uint256 dividend) {
        require(dividendExists(dividend));
        _;
    }

    /// @notice Constructor function connecting the Idea entity and creating a Bank with an administrator.
    constructor(uint256 amount) Idea(amount) {
        _createBank("main",msg.sender);
        _setPermit("sNS", msg.sender, PermitState.administrator);
        _setPermit("iS", msg.sender, PermitState.administrator);
        _setPermit("iD", msg.sender, PermitState.administrator);
        _setPermit("dD", msg.sender, PermitState.administrator);
        _setPermit("mB", msg.sender, PermitState.administrator);
        _setPermit("lE", msg.sender, PermitState.administrator);
        _setPermit("mAT", msg.sender, PermitState.administrator);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param shard The shard that was valid at the clock of the Dividend creation
    /// @param dividend The dividend to be claimed.
    function claimDividend(bytes32 shard, uint256 dividend) external onlyHolder(shard) onlyExistingDividend(dividend) onlyIfActive {
        require(shardExisted(shard,dividend), "NAF");
        require(hasClaimedDividend[dividend][shard] == false, "AC");
        hasClaimedDividend[dividend][shard] = true;
        uint256 dividendValue = infoByDividend[dividend].value * infoByShard[shard].amount / totalShardAmountByClock[clock];
        require(dividendValue != 0, "DTS");
        residualByDividend[dividend] -= dividendValue;
        _transferToken(infoByDividend[dividend].tokenAddress,dividendValue,msg.sender);
        emit ActionTaken("cD",abi.encode(dividend,dividendValue),msg.sender);
    }

    /// @notice Adds a token address to the registry. Also approves any future receipts of said token unless removed again.
    /// @param tokenAddress The token address to be registered.
    function registerTokenAddress(address tokenAddress) external onlyWithPermit("mAT") onlyIfActive {
        _registerTokenAddress(tokenAddress);
    }

    /// @notice Removes a token address from the registry. Also cancels any future receipts of said token unless added again.
    /// @param tokenAddress The token address to be unregistered.
    function unregisterTokenAddress(address tokenAddress) external onlyWithPermit("mAT") onlyIfActive {
        _unregisterTokenAddress(tokenAddress);
    }

    /// @notice Issues new shards and puts them for sale.
    /// @param tokenAddress The token address the shards are put for sale for.
    /// @param price The price per token.
    /// @param to The specifically set buyer of the issued shards. Open to anyone, if address(0).
    function issueShards(uint256 amount, address tokenAddress, uint256 price, address to) external onlyWithPermit("iS") {
        _issueShards(amount,tokenAddress,price,to);
    }

    /// @notice Creates and issues a Dividend (to all current shareholders) of a token amount from a given Bank.
    /// @param bankName The name of the Bank to issue the Dividend from.
    /// @param tokenAddress The address of the token to make up the Dividend.
    /// @param value The value/amount of the token to be issued in the Dividend.
    function issueDividend(string memory bankName, address tokenAddress, uint256 value) external onlyWithPermit("iD") onlyBankAdmin(bankName) {
        _issueDividend(bankName,tokenAddress,value);  
    }

    /// @notice Dissolves a Dividend and moves its last contents to the 'main' Bank.
    /// @param dividend The Dividend to be dissolved.
    function dissolveDividend(uint256 dividend) external onlyWithPermit("dD") {
        _dissolveDividend(dividend);
    }

    /// @notice Creates a new Bank.
    /// @param bankName The name of the Bank to be created.
    /// @param bankAdmin The address of the first Bank administrator.
    function createBank(string memory bankName, address bankAdmin) external onlyWithPermit("mB") onlyIfActive {
       _createBank(bankName,bankAdmin);
    }

    /// @notice Adds a new given administrator to a given Bank.
    /// @param bankName The name of the Bank to which the new administrator is to be added.
    /// @param bankAdmin The address of the new Bank administrator to be added.
    function addBankAdmin(string memory bankName, address bankAdmin) external onlyWithPermit("mB") onlyBankAdmin(bankName) {
        require(isShardHolder(bankAdmin) || allowNonShardHolders, "NSHNA");
        _addBankAdmin(bankName,bankAdmin);
    }

    /// @notice Removes a given administrator of a given Bank.
    /// @param bankName The name of the Bank from which the given administrator is to be removed.
    /// @param bankAdmin The address of the current Bank administrator to be removed.
    function removeBankAdmin(string memory bankName, address bankAdmin) external onlyPermitAdmin("mB") onlyBankAdmin(bankName) {
        _removeBankAdmin(bankName,bankAdmin);
    }

    /// @notice Deletes a given Bank.
    /// @param bankName The name of the Bank to be deleted.
    function deleteBank(string memory bankName) external onlyPermitAdmin("mB") onlyBankAdmin(bankName) {
        _deleteBank(bankName);
    }

    /// @notice Transfers a token bankAdmin a Bank to a recipient.
    /// @param bankName The name of the Bank from which the token is to be transferred.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function transferTokenFromBank(string memory bankName, address tokenAddress, uint256 value, address to) external onlyBankAdmin(bankName) {
        _transferTokenFromBank(bankName,tokenAddress,value,to);
    }

    /// @notice Internally moves a token from one Bank to another.
    /// @param fromBankName The name of the Bank from which the token is to be moved.
    /// @param toBankName The name of the Bank to which the token is to be moved.
    /// @param tokenAddress The address of the token to be moved.
    /// @param value The value/amount of the token to be moved.
    function moveToken(string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) external onlyBankAdmin(fromBankName) {
        _moveToken(fromBankName,toBankName,tokenAddress,value);
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param account The address, whose permit state is to be set.
    /// @param permitName The name of the permit, whose state is to be set.
    /// @param newState The new Permit State to be applied.
    function setPermit(string memory permitName, address account, PermitState newState) external onlyPermitAdmin(permitName) {
        require(isShardHolder(account) || allowNonShardHolders, "NSHNA");
        require(permits[permitName][account] != newState, "AHP");
        _setPermit(permitName,account,newState);

    }

    /// @notice Sets the state of a specified base permit.
    /// @param permitName The name of the base permit, whose state is to be set.
    /// @param newState The new base Permit State to be applied.
    function setBasePermit(string memory permitName, PermitState newState) external onlyPermitAdmin(permitName) {
        require(basePermits[permitName] != newState, "AS");
        _setBasePermit(permitName,newState);
    }

    /// @notice Sets the state of the Non Shard Holders.
    /// @param newState The Boolean state to be applied.
    function setNonShardHolderState(bool newState) external onlyWithPermit("sNS") {
        require(allowNonShardHolders != newState, "AS");
        _setNonShardHolderState(newState);
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    function liquidize() external onlyWithPermit("lE") {
        _liquidize();
    }

    /// @notice Returns the balance of a bank.
    /// @param bankName The name of the Bank.
    /// @param tokenAddress The address of the token balance to check for.
    function getBankBalance(string memory bankName, address tokenAddress) public view returns(uint256) {
        return balanceByBank[bankName][tokenAddress];
    }
    
    /// @notice Returns the token of a dividend.
    /// @param dividend The Dividend to be checked for.
    function getDividendToken(uint256 dividend) public view returns(address) {
        return infoByDividend[dividend].tokenAddress;
    }
    
    /// @notice Returns the total value of a dividend.
    /// @param dividend The Dividend to be checked for.
    function getDividendValue(uint256 dividend) public view returns(uint256) {
        return infoByDividend[dividend].value;
    }

    /// @notice Returns the residual value of a dividend.
    /// @param dividend The Dividend to be checked for.
    function getDividendResidual(uint256 dividend) public view returns(uint256) {
        return residualByDividend[dividend];
    }

    /// @notice Returns a boolean stating if a given Bank exists.
    /// @param bankName The name of the Bank to be checked for.
    function bankExists(string memory bankName) public view returns(bool) {
        return validBanks[bankName] == true;
    }

    /// @notice Returns a boolean stating if a given Bank is empty.
    /// @param bankName The name of the Bank to be checked for.
    function bankIsEmpty(string memory bankName) public view returns(bool) {
        return storedTokenAddressesByBank[bankName] == 0 && balanceByBank[bankName][address(0)] == 0;
    }
    
    /// @notice Returns a boolean stating if a given Dividend exists.
    /// @param dividend The Dividend to be checked for.
    function dividendExists(uint256 dividend) public view returns(bool) {
      return validDividends[dividend];
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given bank.
    /// @param account The address to be checked for.
    /// @param bankName The name of the Bank to be checked for.
    function isBankAdmin(string memory bankName, address account) public view returns(bool) {
        return adminOfBank[bankName][account] == true || isPermitAdmin("mB",account);
    }

    /// @notice Returns a boolean stating if a given address has a given permit or not.
    /// @param permitName The name of the permit to be checked for.
    /// @param account The address to be checked for.
    function hasPermit(string memory permitName, address account) public view returns(bool) {
        if (!(isShardHolder(account) || allowNonShardHolders)) {return false;}
        return permits[permitName][account] >= PermitState.authorized || basePermits[permitName] >= PermitState.authorized;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given permit or not.
    /// @param permitName The name of the permit to be checked for.
    /// @param account The address to be checked for.
    function isPermitAdmin(string memory permitName, address account) public view returns(bool) {
        if (!(isShardHolder(account) || allowNonShardHolders)) {return false;}
        return permits[permitName][account] == PermitState.administrator || basePermits[permitName] == PermitState.administrator;
    }

    /// @notice Creates and issues a Dividend (to all current shareholders) of a token amount from a given Bank.
    /// @param bankName The name of the Bank to issue the Dividend from.
    /// @param tokenAddress The address of the token to make up the Dividend.
    /// @param value The value/amount of the token to be issued in the Dividend.
    function _issueDividend(string memory bankName, address tokenAddress, uint256 value) internal onlyIfActive {
        uint256 transferClock = clock;
        require(value <= balanceByBank[bankName][tokenAddress], "IF");
        balanceByBank[bankName][tokenAddress] -= value;
        if (balanceByBank[bankName][tokenAddress] == 0 && tokenAddress != address(0)) {
            storedTokenAddressesByBank[bankName] -= 1;
        }
        infoByDividend[transferClock] = DividendInfo({
            tokenAddress:tokenAddress,
            value:value
        });
        residualByDividend[transferClock] = value;
        validDividends[transferClock] = true;
        emit ActionTaken("iD",abi.encode(bankName,tokenAddress,value),msg.sender);
    }

    /// @notice Dissolves a Dividend and moves its last contents to the 'main' Bank.
    /// @param dividend The Dividend to be dissolved.
    function _dissolveDividend(uint256 dividend) internal onlyExistingDividend(dividend) onlyIfActive {
        validDividends[dividend] = false; // -1 to distinguish between empty values;
        balanceByBank["main"][infoByDividend[dividend].tokenAddress] += residualByDividend[dividend];
        emit ActionTaken("dD",abi.encode(dividend),msg.sender);

    }

    /// @notice Creates a new Bank.
    /// @param bankName The name of the Bank to be created.
    /// @param bankAdmin The address of the first Bank administrator.
    function _createBank(string memory bankName, address bankAdmin) internal onlyIfActive {
        require(!bankExists(bankName), "AE");
        adminOfBank[bankName][bankAdmin] = true;
        validBanks[bankName] = true;
        emit ActionTaken("cB",abi.encode(bankName,bankAdmin),msg.sender);

    }

    /// @notice Adds a new given administrator to a given Bank.
    /// @param bankName The name of the Bank to which the new administrator is to be added.
    /// @param bankAdmin The address of the new Bank administrator to be added.
    function _addBankAdmin(string memory bankName, address bankAdmin) internal onlyIfActive {
        require(hasPermit("mB",bankAdmin),"NP");
        adminOfBank[bankName][bankAdmin] = true;
        emit ActionTaken("aA",abi.encode(bankName,bankAdmin),msg.sender);

    }

    /// @notice Removes a given administrator of a given Bank.
    /// @param bankName The name of the Bank from which the given administrator is to be removed.
    /// @param bankAdmin The address of the current Bank administrator to be removed.
    function _removeBankAdmin(string memory bankName, address bankAdmin) internal onlyIfActive {
        require(isBankAdmin(bankName,bankAdmin));
        adminOfBank[bankName][bankAdmin] = false;
        emit ActionTaken("rA",abi.encode(bankName,bankAdmin),msg.sender);

    }

    /// @notice Deletes a given Bank.
    /// @param bankName The name of the Bank to be deleted.
    function _deleteBank(string memory bankName) internal onlyIfActive {
        require(bankExists(bankName), "UB!");
        require(keccak256(bytes(bankName)) != keccak256(bytes("main")), "MB");
        require(bankIsEmpty(bankName), "BE");
        validBanks[bankName] = false;
        emit ActionTaken("dB",abi.encode(bankName),msg.sender);

    }

    /// @notice Transfers a token from a Bank to a recipient.
    /// @param bankName The name of the Bank from which the token is to be transferred.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function _transferTokenFromBank(string memory bankName, address tokenAddress, uint256 value, address to) internal onlyIfActive {
        require(value <= balanceByBank[bankName][tokenAddress], "IF");
        _transferToken(tokenAddress,value,to);
        balanceByBank[bankName][tokenAddress] -= value;
        if (balanceByBank[bankName][tokenAddress] == 0 && tokenAddress != address(0)) {
            storedTokenAddressesByBank[bankName] -= 1;
        }
        emit ActionTaken("tT",abi.encode(bankName,tokenAddress,value,to),msg.sender);
    }

    /// @notice Internally moves a token from one Bank to another.
    /// @param fromBankName The name of the Bank from which the token is to be moved.
    /// @param toBankName The name of the Bank to which the token is to be moved.
    /// @param tokenAddress The address of the token to be moved.
    /// @param value The value/amount of the token to be moved.
    function _moveToken(string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) internal onlyExistingBank(toBankName) onlyIfActive {
        require(value <= balanceByBank[fromBankName][tokenAddress], "IF");
        balanceByBank[fromBankName][tokenAddress] -= value;
        if (tokenAddress != address(0)) {
            if (balanceByBank[fromBankName][tokenAddress] == 0) {
                storedTokenAddressesByBank[fromBankName] -= 1;

            }
            if (balanceByBank[toBankName][tokenAddress] == 0) {
                storedTokenAddressesByBank[toBankName] += 1;
            }
        }
        balanceByBank[toBankName][tokenAddress] += value;
        emit ActionTaken("mT",abi.encode(fromBankName,toBankName,tokenAddress,value),msg.sender);

    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param permitName The name of the permit, whose state is to be set.
    /// @param account The address, whose permit state is to be set.
    /// @param newState The new Permit State to be applied.
    function _setPermit(string memory permitName, address account, PermitState newState) internal onlyIfActive {
        permits[permitName][account] = newState;
        emit ActionTaken("sP",abi.encode(permitName,account,newState),msg.sender);

    }

    /// @notice Sets the state of a specified base permit.
    /// @param permitName The name of the base permit, whose state is to be set.
    /// @param newState The new base Permit State to be applied.
    function _setBasePermit(string memory permitName, PermitState newState) internal onlyIfActive {
        basePermits[permitName] = newState;
        emit ActionTaken("sB",abi.encode(permitName,newState),msg.sender);
    }

    /// @notice Sets the state of the Non Shard Holders.
    /// @param newState The Boolean state to be applied.
    function _setNonShardHolderState(bool newState) internal onlyIfActive {
        allowNonShardHolders = newState;
        emit ActionTaken("sNS",abi.encode(newState),msg.sender);
    }

    /// @notice Removes a token address from the registry. Also cancels any future receipts of said token unless added again.
    /// @param tokenAddress The token address to be unregistered.
    function _unregisterTokenAddress(address tokenAddress) override internal {
        super._unregisterTokenAddress(tokenAddress);
        emit ActionTaken("uT",abi.encode(tokenAddress),msg.sender);
    }

    /// @notice Adds a token address to the registry. Also approves any future receipts of said token unless removed again.
    /// @param tokenAddress The token address to be registered.
    function _registerTokenAddress(address tokenAddress) override internal {
        super._registerTokenAddress(tokenAddress);
        emit ActionTaken("rT",abi.encode(tokenAddress),msg.sender);
    }

    /// @notice Keeps track of a token receipt by adding it to the registry
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) override internal {
        super._processTokenReceipt(tokenAddress, value, from);
        // Then: Bank logic
        if (balanceByBank["main"][tokenAddress] == 0 && tokenAddress != address(0)) {
            storedTokenAddressesByBank["main"] += 1;
        }
        balanceByBank["main"][tokenAddress] += value;
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Liquidizes and dissolves the entity. This cannot be undone.
    function _liquidize() override internal {
        super._liquidize();
        emit ActionTaken("lE","",msg.sender);
    }

}