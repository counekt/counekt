pragma solidity ^0.8.4;

import "./idea.sol";

/// @title An extension of the Idea providing an administrable interface.
/// @author Frederik W. L. Christoffersen
/// @notice This contract adds administrability via permits and internally closed money supplies.
contract Administrable is Idea {

    /// @notice A struct representing the information of a Bank used to encapsel funds and tokens restricted to a few spenders.
    /// @param name The name of the Bank. Used for identification.
    /// @param storedTokenAddresses An unsigned integer representing the amount of stored kinds of tokens.
    /// @param balance A mapping pointing to a value/amount of a stored token, given a token address.
    /// @param isAdmin A mapping pointing to a boolean stating if a given address is a valid Bank administrator that have restricted control of the Bank's funds.
    struct BankInfo {
        string name;
        uint256 storedTokenAddresses;
        mapping(address => uint256) balance;
        mapping(address => bool) isAdmin;
    }

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
    /// @param creationTime The block.timestamp at which the Dividend was created.
    /// @param tokenAddress The address of the token, in which the value of the Dividend is issued.
    /// @param originalValue The original value/amount of the Dividend before claimants.
    /// @param value The value/amount of the Dividend.
    /// @param hasClaimed Mapping pointing to a boolean stating if the owner of a Shard has claimed their fair share of the Dividend.
    struct DividendInfo {
        uint256 creationTime;
        address tokenAddress;
        uint256 originalValue;
        uint256 value;
        mapping(bytes32  => bool) hasClaimed;
    }

    /// @notice A mapping pointing to a Boolean rule, given the name of the rule.
    mapping(string => bool) rules;

    /// @notice A mapping pointing to a boolean stating if a given Bank is valid/exists or not.
    mapping(string => bool) validBanks;
    
    /// @notice A mapping pointing to the info of a Bank, given the name of it.
    mapping(string => BankInfo) infoByBank;

    /// @notice A mapping pointing to another mapping, pointing to a Permit State, given the address of a permit holder, given the name of the permit.
    /// @custom:illustration permits[permitName][address] == PermitState.authorized || PermitState.administrator;
    mapping(string => mapping(address => PermitState)) permits;

    /// @notice A mapping pointing to a base Permit State, given the name of the permit.
    mapping(string => PermitState) basePermits;
    
    /// @notice A mapping pointing to a boolean stating if a given Dividend is valid or not.
    mapping(bytes32 => bool) validDividends;

    /// @notice A mapping pointing to the info of a Dividend given the creation time of the Dividend.
    mapping(uint256 => DividendInfo) infoByDividend;


    /// @notice The Dividend latest and most recently issued.
    uint256 latestDividend;

    /// @notice Event that triggers when a Dividend is issued.
    /// @param dividend The Dividend that was issued.
    /// @param by The initiator of the Dividend issuance.
    event DividendIssued(
        uint256 dividend,
        address by
    );

    /// @notice Event that triggers when a Dividend is dissolved.
    /// @param dividend The Dividend that was dissolved.
    /// @param valueLeft The remaining value of the Dividend that was dissolved (goes to the 'main' Bank).
    /// @param by The initiator of the Dividend dissolution.
    event DividendDissolved(
        uint256 dividend,
        uint256 valueLeft,
        address by
    );

    /// @notice Event that triggers when a Dividend is claimed.
    /// @param dividend The Dividend that was claimed.
    /// @param by The claimant of the Dividend.
    event DividendClaimed(
        uint256 dividend,
        address by
    );

    /// @notice Event that triggers when a token is transferred.
    /// @param bankName The name of the Bank where the token was transferred from.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    /// @param to The recipient of the transferred token.
    /// @param by The initiator of the Token transfer.
    event TokenTransferedFromBank(
        string bankName,
        address tokenAddress,
        uint256 value,
        address to,
        address by
    );

    /// @notice Event that triggers when a token is moved internally from one Bank to another.
    /// @param fromBankName The name of the Bank where the token was moved away from.
    /// @param toBankName The name of the Bank where the token was moved to.
    /// @param tokenAddress The address of the token that was moved (address(0) if ether).
    /// @param value The value/amount that was moved.
    /// @param by The initiator of the Token movement.
    event TokenMoved(
        string fromBankName,
        string toBankName,
        address tokenAddress,
        uint256 value,
        address by
    );

    /// @notice Event that triggers when a new Bank is created.
    /// @param name The name of the newly created Bank.
    /// @param by The initiator of the Bank creation.
    event BankCreated(
        string name,
        address by
    );

    /// @notice Event that triggers when a new admin has been added to a given Bank.
    /// @param name The name of the Bank to from an admin was added.
    /// @param admin The address of the admin that was added.
    /// @param by The initiator of the Bank admin addition.
    event BankAdminAdded(string name, address admin, address by);

    /// @notice Event that triggers when a former admin has been removed from a given Bank.
    /// @param name The name of the Bank where from an admin was removed.
    /// @param admin The address of the admin that was removed.
    /// @param by The initiator of the Bank admin removal.
    event BankAdminRemoved(string name,address admin, address by);


    /// @notice Event that triggers when a Bank is deleted.
    /// @param name The name of the Bank that was deleted.
    /// @param by The initiator of the Bank deletion.
    event BankDeleted(
        string name,
        address by
    );

    /// @notice Event that triggers when a permit is set.
    /// @param holder The address of the holder of the permit that was set.
    /// @param name The name of the permit that was set.
    /// @param newState The new state of the permit.
    /// @param by The initiator of the Permit State setting.
    event PermitSet(
        address holder,
        string name,
        PermitState newState,
        address by
    );

    /// @notice Event that triggers when a base permit is set.
    /// @param name The name of the permit that was set.
    /// @param newState The new state of the permit.
    /// @param by The initiator of the base Permit State setting.
    event BasePermitSet(
        string name,
        PermitState newState,
        address by
    );

    /// @notice Event that triggers when a rule is set.
    /// @param name The name of the rule that was set.
    /// @param newState The new state of the permit.
    /// @param by The initiator of the rule setting.
    event RuleSet(
        string name,
        bool newState,
        address by
    );
    
    /// @notice Modifier that makes sure a given permit exists.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyValidPermit(string memory permitName) {
        require(isValidPermit(permitName), "The given permit name does NOT exist!");
        _;
    }

    /// @notice Modifier that makes sure msg.sender has a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyWithPermit(string memory permitName) {
        require(hasPermit(msg.sender, permitName));
        _;
    }
    
    /// @notice Modifier that makes sure msg.sender is an admin of a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyPermitAdmin(string memory permitName) {
        require(isPermitAdmin(msg.sender,permitName));
        _;

    }

    /// @notice Modifier that makes sure msg.sender is admin of a given bank.
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyBankAdmin(string memory bankName) {
        require(isBankAdmin(msg.sender, bankName));
        _;
    }

    /// @notice Modifier that makes sure a given bank exists
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyExistingBank(string memory bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' does NOT exist!");
        _;
    }
    
    /// @notice Modifier that makes sure a given dividend exists and is valid
    /// @param dividend The Dividend to be checked for.
    modifier onlyExistingDividend(uint256 dividend) {
        require(dividendExists(dividend));
        _;
    }

    /// @notice Constructor function connecting the Idea entity and creating a Bank with an administrator.
    constructor() {
        _createBank("main",msg.sender,this.address);
    }

    /// @notice Creates and issues a Dividend (to all current shareholders) of a token amount from a given Bank.
    /// @param bankName The name of the Bank to issue the Dividend from.
    /// @param tokenAddress The address of the token to make up the Dividend.
    /// @param value The value/amount of the token to be issued in the Dividend.
    function issueDividend(string memory bankName, address tokenAddress, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdmin(bankName) onlyIfActive {
        _issueDividend(bankName,tokenAddress,value, msg.sender);
    }

    /// @notice Dissolves a Dividend and moves its last contents to the 'main' Bank.
    /// @param dividend The Dividend to be dissolved.
    function dissolveDividend(uint256 dividend) external onlyWithPermit("dissolveDividend") onlyExistingDividend onlyIfActive {
        _dissolveDividend(dividend, msg.sender);
    }

    /// @notice Creates a new Bank.
    /// @param bankName The name of the Bank to be created.
    /// @param bankAdmin The address of the first Bank administrator.
    function createBank(string memory bankName, address bankAdmin) external onlyWithPermit("manageBank") {
       _createBank(bankName, bankAdmin, msg.sender);
    }

    /// @notice Adds a new given administrator to a given Bank.
    /// @param bankName The name of the Bank to which the new administrator is to be added.
    /// @param bankAdmin The address of the new Bank administrator to be added.
    function addBankAdmin(string memory bankName, address bankAdmin) external onlyWithPermit("manageBank") onlyBankAdmin(bankName) {
        _addBankAdmin(bankName, bankAdmin);
    }

    /// @notice Removes a given administrator of a given Bank.
    /// @param bankName The name of the Bank from which the given administrator is to be removed.
    /// @param bankAdmin The address of the current Bank administrator to be removed.
    function removeBankAdmin(string memory bankName, address bankAdmin) external {
        require(isPermitAdmin(msg.sender, "manageBank"));
        require(isBankAdmin(bankName,bankAdmin));
        _removeBankAdmin();
    }

    /// @notice Deletes a given Bank.
    /// @param bankName The name of the Bank to be deleted.
    function deleteBank(string memory bankName) external onlyWithPermit("manageBank") onlyBankAdmin(bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exists!");
        _deleteBank(bankName, msg.sender);
    }

    /// @notice Transfers a token from a Bank to a recipient.
    /// @param bankName The name of the Bank from which the token is to be transferred.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function transferTokenFromBank(string memory bankName, address tokenAddress, uint256 value, address to) external onlyBankAdmin(bankName) {
        _transferTokenFromBank(bankName,tokenAddress,value,to,msg.sender);
    }

    /// @notice Internally moves a token from one Bank to another.
    /// @param fromBankName The name of the Bank from which the token is to be moved.
    /// @param toBankName The name of the Bank to which the token is to be moved.
    /// @param tokenAddress The address of the token to be moved.
    /// @param value The value/amount of the token to be moved.
    function moveToken(string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value) external onlyBankAdmin(fromBankName) {
        _moveToken(fromBankName,toBankName,tokenAddress,value,msg.sender);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param shard The shard that was valid at the time of the Dividend creation
    /// @param dividend The dividend to be claimed.
    function claimDividend(bytes32 shard, uint256 dividend) external onlyExistingDividend onlyIfActive {
        require(active == true, "Can't claim dividends from a liquidized entity! Check liquidization instead.");
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(infoByDividend[dividend].hasClaimed[msg.sender] == false, "Already claimed Dividend!");
        require(shardExisted(shard,dividend), "Not applicable for Dividend!");
        infoByDividend[dividend].hasClaimed[msg.sender] = true;
        uint256 dividendValue = infoByShard[shardByOwner[msg.sender]].fraction.numerator / infoByShard[shardByOwner[msg.sender]].fraction.denominator * infoByDividend[dividend].originalValue;
        infoByDividend[dividend].value -= dividendValue;
        _transferToken(infoByDividend[dividend].tokenAddress,dividendValue,msg.sender);
        emit DividendClaimed(dividend,dividendValue,msg.sender);
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param _address The address, whose permit state is to be set.
    /// @param permitName The name of the permit, whose state is to be set.
    /// @param newState The new Permit State to be applied.
    function setPermit(address _address, string memory permitName, PermitState newState) external onlyPermitAdmin(permitName) {
        require(permits[permitName][_address] != newState, "Address already has Permit '" + permitName + "="+string(newState)+"'");
        _setPermit(_address, permitName, newState, msg.sender);
    }

    /// @notice Sets the state of a specified base permit.
    /// @param permitName The name of the base permit, whose state is to be set.
    /// @param newState The new base Permit State to be applied.
    function setBasePermit(string memory permitName, PermitState newState) external onlyPermitAdmin(permitName) {
        require(basePermits[permitName] != newState, "BasePermit already existing '" + permitName + "="+string(newState)+"'");
        _setBasePermit(permitName,newState,msg.sender);
    }

    /// @notice Sets the state of a specified rule.
    /// @param ruleName The name of the rule, whose state is to be set.
    /// @param newState The Boolean rule state to be applied.
    function setRule(string memory ruleName, bool newState) external hasPermit("setRule") {
        require(rules[ruleName] != newState, "Rule is already set to '" + ruleName + "="+string(newState)+"'");
        _setRule(ruleName, newState, msg.sender);
    }

    /// @notice Returns a boolean stating if a given rule is valid/exists or not.
    /// @param ruleName The name of the rule to be checked for.
    function isValidRule(string memory ruleName) public pure returns(bool) {
        if(ruleName == "allowNonShardHolders") {
            return true;
        }
        else {
            return false;
        }
    }

    /// @notice Returns a boolean stating if a given permit is valid/exists or not.
    /// @param permitName The name of the permit to be checked for.
    function isValidPermit(string memory permitName) virtual public pure returns(bool) {
            if(permitName == "setRule") {
                return true;
            }
            if(permitName == "issueDividend") {
                return true;
            }
            if(permitName == "dissolveDividend") {
                return true;
            }
            if(permitName == "manageBank") {
                return true;
            }
            if(permitName == "liquidizeEntity") {
                return true;
            }
            else {
                return false;
            }
    }

    /// @notice Returns a boolean stating if a given Bank exists.
    /// @param bankName The name of the Bank to be checked for.
    function bankExists(string memory bankName) public view returns(bool) {
        return validBanks[bankName] == true;
    }

    /// @notice Returns a boolean stating if a given Bank is empty.
    /// @param bankName The name of the Bank to be checked for.
    function bankIsEmpty(string memory bankName) public view returns(bool) {
        BankInfo memory bankInfo = infoByBank[bankName];
        return bankInfo.storedTokenAddresses == 0 && bankInfo.balance[address(0)] == 0;
    }
    
    /// @notice Returns a boolean stating if a given Dividend exists.
    /// @param dividend The Dividend to be checked for.
    function dividendExists(uint256 dividend) public view returns(bool) {
      return validDividends[dividend] == true;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given bank.
    /// @param _address The address to be checked for.
    /// @param bankName The name of the Bank to be checked for.
    function isBankAdmin(address _address, string memory bankName) public view returns(bool) {
        return infoByBank[bankName].isAdmin[_address] == true || isPermitAdmin(_address,"manageBank");
    }

    /// @notice Returns a boolean stating if a given address has a given permit or not.
    /// @param _address The address to be checked for.
    /// @param permitName The name of the permit to be checked for.
    function hasPermit(address _address, string memory permitName) public view returns(bool) {
        if (_address == this.address) {return true;}
        if (!(isShardHolder(_address) || rules["allowNonShardHolders"])) {return false;}
        return permits[permitName][_address] >= PermitState.authorized || basePermits[permitName] >= PermitState.authorized;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given permit or not.
    /// @param _address The address to be checked for.
    /// @param permitName The name of the permit to be checked for.
    function isPermitAdmin(address _address, string memory permitName) public view returns(bool) {
        if (_address == this.address) {return true;}
        if (!(isShardHolder(_address) || rules["allowNonShardHolders"])) {return false;}
        return permits[permitName][_address] == PermitState.administrator || basePermits[permitName] == PermitState.administrator;
    }
    
    /// @notice Sets the state of a specified permit of a given address.
    /// @param _address The address, whose permit state is to be set.
    /// @param permitName The name of the permit, whose state is to be set.
    /// @param newState The new Permit State to be applied.
    /// @param by The initiator of the Permit State setting.
    function _setPermit(address _address, string memory permitName, PermitState newState, address by) internal onlyIfActive onlyValidPermit(permitName) {
        permits[permitName][_address] = newState;
        emit PermitSet(_address,permitName,newState,by);
    }

    /// @notice Sets the state of a specified permit of a given address.
    /// @param permitName The name of the Base Permit, whose State is to be set.
    /// @param newState The new Base Permit State to be applied.
    /// @param by The initiator of the Base Permit State setting.
    function _setBasePermit(string memory permitName, PermitState newState, address by) internal onlyIfActive onlyValidPermit(permitName) {
        basePermits[permitName] = newState;
        emit BasePermitSet(permitName,newState,by);
    }

    /// @notice Sets the state of a specified rule.
    /// @param ruleName The name of the permit, whose state is to be set.
    /// @param newState The new Boolean rule state to be applied.
    /// @param by The initiator of the rule state setting.
    function _setRule(string memory ruleName, bool newState, address by) internal onlyIfActive {
        require(isValidRule(ruleName), "The rule name, '"+ruleName+"' doesn't exist and isn't valid!");
        rules[ruleName] = newState;
        emit RuleSet(ruleName,newState,by);
    }

    /// @notice Creates a new Bank.
    /// @param bankName The name of the Bank to be created.
    /// @param bankAdmin The address of the first Bank administrator.
    /// @param by The initiator of the Bank creation.
    function _createBank(string memory bankName, address bankAdmin, address by) internal onlyIfActive {
        require(!bankExists(bankName), "Bank '"+bankName+"' already exists!");
        require(hasPermit(bankAdmin,"manageBank"),"Only holders of the 'manageBank' Permit can be Bank Administrators!");
        BankInfo memory bankInfo = new BankInfo();
        bankInfo.name = bankName;
        bankInfo.isAdmin[bankAdmin] = true;
        infoByBank[bankName] = bankInfo;
        validBanks[bankName] = true;
        emit BankCreated(bankName,bankAdmin,by);
    }

    /// @notice Adds a new given administrator to a given Bank.
    /// @param bankName The name of the Bank to which the new administrator is to be added.
    /// @param bankAdmin The address of the new Bank administrator to be added.
    /// @param by The initiator of the Bank administrator addition.
    function _addBankAdmin(string memory bankName, address bankAdmin, address by) internal onlyIfActive {
        require(isBankAdmin(by,bankName));
        require(hasPermit(bankAdmin,"manageBank"),"Only holders of the 'manageBank' Permit can be Bank Administrators!");
        BankInfo memory bankInfo = infoByBank[bankName];
        bankInfo.isAdmin[bankAdmin] = true;
        emit BankAdminAdded(bankName,bankAdmin,by);
    }

    /// @notice Removes a given administrator of a given Bank.
    /// @param bankName The name of the Bank from which the given administrator is to be removed.
    /// @param bankAdmin The address of the current Bank administrator to be removed.
    /// @param by The initiator of the Bank Administrator removal.
    function _removeBankAdmin(string memory bankName, address bankAdmin, address by) internal onlyIfActive {
        BankInfo memory bankInfo = infoByBank[bankName];
        bankInfo.isAdmin[bankAdmin] = false;
        emit BankAdminRemoved(bankName,bankAdmin,by);
    }

    /// @notice Deletes a given Bank.
    /// @param bankName The name of the Bank to be deleted.
    /// @param by The initiator of the Bank deletion.
    function _deleteBank(string memory bankName, address by) internal onlyIfActive {
        require(bankName != "main", "Can't delete the main bank!");
        require(bankIsEmpty(bankName), "Bank '"+bankName+"' must be empty before being deleted!");
        BankInfo memory bankInfo = infoByBank[bankName];
        validBanks[bankName] = false;
        emit BankDeleted(bankName, by);
    }

    /// @notice Creates and issues a Dividend (to all current shareholders) of a token amount from a given Bank.
    /// @param bankName The name of the Bank to issue the Dividend from.
    /// @param tokenAddress The address of the token to make up the Dividend.
    /// @param value The value/amount of the token to be issued in the Dividend.
    /// @param by The initiator of the Dividend issuance.
    function _issueDividend(string memory bankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(bankName) {
        uint256 transferTime = block.timestamp;
        BankInfo memory bankInfo = infoByBank[bankName];
        require(transferTime > latestDividend, "Dividends must be issued at least one second between each other.");
        require(value <= bankInfo.balance[tokenAddress], "Dividend value "+string(value)+" can't be more than bank value "+bankInfo.balance[tokenAddress]);
        bankInfo.balance[tokenAddress] -= value;
        if (bankInfo.balance[tokenAddress] == 0) {
            bankInfo.storedTokenAddresses -= 1;
        }
        DividendInfo memory dividendInfo = new DividendInfo();
        dividendInfo.creationTime = transferTime;
        dividendInfo.tokenAddress = tokenAddress;
        dividendInfo.originalValue = value;
        dividendInfo.value = value;
        infoByDividend[transferTime] = dividendInfo; 
        validDividends[transferTime] = true;
        latestDividend = transferTime;
        emit DividendIssued(transferTime, by);
    }

    /// @notice Dissolves a Dividend and moves its last contents to the 'main' Bank.
    /// @param dividend The Dividend to be dissolved.
    /// @param by The initiator of the dissolution.
    function _dissolveDividend(uint256 dividend, address by) internal onlyIfActive {
        validDividends[dividend] = false; // -1 to distinguish between empty values;
        uint256 valueLeft = infoByDividend[dividend].value;
        infoByDividend[dividend].value = 0;
        infoByBank["main"].balance[infoByDividend[dividend].tokenAddress] += valueLeft;
        emit DividendDissolved(dividend, valueLeft, by);
    }

    /// @notice Transfers a token from a Bank to a recipient.
    /// @param bankName The name of the Bank from which the token is to be transferred.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    /// @param by The initiator of the transfer.
    function _transferTokenFromBank(string memory bankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(bankName) {
        BankInfo memory bankInfo = infoByBank[bankName];
        require(value <= bankInfo.balance[tokenAddress], "The value transferred "+string(value)+" from '"+bankName+"' can't be more than the value of that bank:"+bankInfo.balance[tokenAddress]);
        _transferToken(tokenAddress,value,to);
        _processTokenTransfer(bankName,tokenAddress,value,to,by);
        emit TokenTransferedFromBank(bankName,tokenAddress,value,to,by);
    }

    /// @notice Internally moves a token from one Bank to another.
    /// @param fromBankName The name of the Bank from which the token is to be moved.
    /// @param toBankName The name of the Bank to which the token is to be moved.
    /// @param tokenAddress The address of the token to be moved.
    /// @param value The value/amount of the token to be moved.
    /// @param by The initiator of the move.
    function _moveToken(string memory fromBankName, string memory toBankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) onlyIfActive {
        BankInfo memory fromBankInfo = infoByBank[fromBankName];
        BankInfo memory toBankInfo = infoByBank[toBankName];
        require(value <= fromBankInfo.balance[tokenAddress], "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBankInfo.balance[tokenAddress]);
        fromBankInfo.balance[tokenAddress] -= value;
        if (fromBankInfo.balance[tokenAddress] == 0) {
            fromBankInfo.storedTokenAddresses -= 1;

        }
        if (toBankInfo.balance[tokenAddress] == 0) {
            toBankInfo.storedTokenAddresses += 1;
        }
        toBankInfo.balance[tokenAddress] += value;
        emit TokenMoved(fromBankName,toBankName,tokenAddress,value,by);
    }

    /// @notice Keeps track of a token receipt by adding it to the registry
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) override internal {
        super._processTokenReceipt(tokenAddress, value, from);
        // Then: Bank logic
        BankInfo memory bankInfo = infoByBank["main"];
        if (bankInfo.balance[tokenAddress] == 0 && tokenAddress != address(0)) {
            bankInfo.storedTokenAddresses += 1;
        }
        bankInfo.balance[tokenAddress] += value;
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Keeps track of a token transfer and subtracts it from the registry.
    /// @param bankName The name of the Bank from which the token is transferred.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    /// @param to The recipient of the transferred token.
    /// @param by The initiator of the transfer.
    function _processTokenTransferFromBank(string memory bankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(bankName) {
        super._processTokenTransfer(tokenAddress, value, to);
        BankInfo memory bankInfo = infoByBank[bankName];
        bankInfo.balance[tokenAddress] -= value;
        if (bankInfo.balance[tokenAddress] == 0) {
            bankInfo.storedTokenAddresses[tokenAddress] -= 1;
        }
        emit TokenTransfered(bankName,tokenAddress,value,to,by);
    }

}