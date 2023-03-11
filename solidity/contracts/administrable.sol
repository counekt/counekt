pragma solidity ^0.8.4;

/// @title A contract that works as the administrable interface to an Idea.
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administrable entity and only works with an Idea.
contract Administrable {

    /// @notice A struct representing a Bank used to encapsel funds and tokens restricted to a few spenders.
    /// @param name The name of the Bank. Used for identification.
    /// @param storedTokenAddresses An unsigned integer representing the amount of stored kinds of tokens.
    /// @param balance A mapping pointing to a value/amount of a stored token, given a token address.
    /// @param isAdmin A mapping pointing to a boolean stating if a given address is a valid Bank administrator that have restricted control of the Bank's funds.
    struct Bank {
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

    /// @notice A struct representing a Dividend given to all current Shard holders.
    /// @param creationTime The block.timestamp at which the Dividend was created.
    /// @param tokenAddress The address of the token, in which the value of the Dividend is issued.
    /// @param value The value/amount of the Dividend.
    /// @param originalValue The original value/amount of the Dividend before claimants.
    /// @param hasClaimed Mapping pointing to a boolean stating if the owner of a Shard has claimed their fair share of the Dividend.
    struct Dividend {
        uint256 creationTime;
        address tokenAddress;
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) hasClaimed;
    }

    /// @notice The Idea contract entity which the Administrable administers.
    address idea;

    /// @notice Boolean value stating if the Administrable allows non-shard-holders to have permits or not.
    bool allowNonShardHolders;

    /// @notice A mapping pointing to a boolean stating if a given Bank is valid/exists or not.
    mapping(Bank => bool) validBanks;
    
    /// @notice A mapping pointing to a Bank, given the name of it.
    mapping(string => Bank) bankByName;

    /// @notice A mapping pointing to another mapping, pointing to a Permit State, given the address of a permit holder, given the name of the permit.
    /// @custom:illustration permits[permitName][address] == PermitState.authorized || PermitState.administrator;
    mapping(string => mapping(address => PermitState)) permits;
    
    /// @notice A mapping pointing to a boolean stating if a given Dividend is valid or not.
    mapping(Dividend => bool) validDividends;

    /// @notice The Dividend latest and most recently issued.
    Dividend latestDividend;

    /// @notice Event that triggers when a Dividend is issued.
    event DividendIssued(
        Dividend dividend,
        address by
    );

    /// @notice Event that triggers when a Dividend is dissolved.
    event DividendDissolved(
        Dividend dividend,
        uint256 valueLeft,
        address by
    );

    /// @notice Event that triggers when a Dividend is claimed.
    event DividendClaimed(
        Dividend dividend,
        address by
    );

    /// @notice Event that triggers when a token is moved from one Bank to another.
    event TokenMoved(
        string fromBankName,
        string toBankName,
        address tokenAddress,
        uint256 value,
        address by
    );

    /// @notice Event that triggers when a new Bank is created.
    event BankCreated(
        string name,
        address by
    );

    /// @notice Event that triggers when a new admin has been added to a given Bank.
    event BankAdminAdded(string name, address admin, address by);

    /// @notice Event that triggers when a former admin has been removed from a given Bank.
    event BankAdminRemoved(string name,address admin, address by);


    /// @notice Event that triggers when a Bank is deleted.
    event BankDeleted(
        string name,
        address by
    );

    /// @notice Modifier requiring the msg.sender to be the Idea entity.
    modifier onlyIdea() {
        require(idea == msg.sender);
    }

    /// @notice Modifier that makes sure msg.sender has a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyWithPermit(string permitName) {
        require(hasPermit(msg.sender, permitName));
    }
    
    /// @notice Modifier that makes sure msg.sender is an admin of a given permit.
    /// @param permitName The name of the permit to be checked for.
    modifier onlyPermitAdmin(string permitName) {
      require(isPermitAdmin(msg.sender,permitName));
    }

    /// @notice Modifier that makes sure msg.sender is admin of a given bank.
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyBankAdmin(string bankName) {
        require(isBankAdmin(msg.sender, bankName));
    }

    /// @notice Modifier that makes sure a given bank exists
    /// @param bankName The name of the Bank to be checked for.
    modifier onlyExistingBank(string bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' does NOT exist!");
    }
    
    /// @notice Modifier that makes sure a given dividend exists and is valid
    /// @param dividend The Dividend to be checked for.
    modifier onlyExistingDividend(Dividend dividend) {
      require(dividendExists(dividend));
    }

    /// @notice Modifier that makes sure the Idea entity is active and not liquidized/dissolved.
    modifier onlyIfActive() {
        require(idea.active == true, "Idea has been liquidized and isn't active anymore.");
    }

    /// @notice Constructor function connecting the Idea entity and creating a Bank with an administrator.
    /// @dev Creation of the 'main' Bank is a PROBLEM, when connecting to Old Ideas with lots of tokens!!!
    /// @param _idea The address of the Idea to be connected to the Administrable.
    /// @param _creator The address to assigned as the administrator of the "main" Bank
    constructor(address _idea, address _creator) {
        idea = _idea;
        _createBank("main",_creator,this.address);
    }

    /// @notice Receive function that makes sure the Administrable can't receive anything. Only the idea can.
    receive() payable {
        revert;
    }

    /// @inheritdoc _issueDividend
    function issueDividend(string bankName, address tokenAddress, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdministrator(bankName) onlyIfActive {
        _issueDividend(bankName,tokenAddress,value, msg.sender);
    }

    /// @inheritdoc _dissolveDividend
    function dissolveDividend(Dividend dividend) external onlyWithPermit("dissolveDividend") onlyExistingDividend onlyIfActive {
        _dissolveDividend(dividend, msg.sender);
    }

    /// @inheritdoc _createBank
    function createBank(string bankName, address bankAdmin) external onlyWithPermit("manageBank") {
       _createBank(bankName, bankAdmin, msg.sender);
    }

    /// @inheritdoc _addBankAdmin
    function addBankAdmin(string bankName, address bankAdmin) external onlyWithPermit("manageBank") onlyBankAdmin(bankName) {
        _addBankAdmin(bankName, bankAdmin);
    }

    /// @inheritdoc _removeBankAdmin
    function removeBankAdmin(string bankName, address bankAdmin) external {
        require(isPermitAdmin("manageBank"));
        require(isBankAdmin(bankName,bankAdmin));
        _removeBankAdmin();
    }

    /// @inheritdoc _deleteBank
    function deleteBank(string bankName) external onlyWithPermit("manageBank") onlyBankAdmin(bankName) {
        _deleteBank(bankName, msg.sender);
    }

    /// @inheritdoc _transferToken
    function transferToken(string fromBankName, address tokenAddress, uint256 value, address to) external onlyBankAdmin(bankName) {
        _transferToken(fromBankName,tokenAddress,value,to,msg.sender);
    }

    /// @notice Moves money internally from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param toBankName The name of the Bank to move the money to.
    /// @param tokenAddress The address of the token to be moved (address(0) if ether).
    /// @param value The value to be moved.
    function moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value) external onlyBankAdmin(fromBankName) {
        _moveToken(fromBankName,toBankName,tokenAddress,value,msg.sender);
    }

    /// @inheritdoc _liquidize
    function liquidize() external onlyWithPermit("liquidizeEntity") {
        _liquidize(msg.sender);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param shard The shard that was valid at the time of the Dividend creation
    /// @param dividend The dividend to be claimed.
    function claimDividend(Shard shard, Dividend dividend) external onlyExistingDividend onlyIfActive {
        require(active == true, "Can't claim dividends from a liquidized entity! Check liquidization instead.")
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(dividend.hasClaimed[msg.sender] == false, "Already claimed Dividend!");
        require(shardExisted(shard,dividend.creationTime), "Not applicable for Dividend!");
        dividend.hasClaimed[msg.sender] = true;
        dividendValue = idea.shardByOwner[msg.sender].fraction.numerator / idea.shardByOwner[msg.sender].fraction.denominator * dividend.originalValue;
        dividend.value -= dividendValue;
        _transferToken(dividend.tokenAddress,dividendValue,msg.sender);
        emit DividendClaimed(dividend,dividendValue,msg.sender);
        if (dividend.value == 0) {
            _dissolveDividend(dividend);
        }
    }

    /// @inheritdoc _changePermit
    function changePermit(address shardHolder, string permitName, PermitState newState) external onlyPermitAdmin(permitName) {
        _changePermit(shardHolder, permitName, newState);
    }

    /// @inheritdoc _processTokenReceipt
    function processTokenReceipt(address tokenAddress, uint256 value, address from) external onlyIdea {
        _processTokenReceipt(tokenAddress,value,from);
    }

    // @notice Creates and returns the address of a new Administrable instance.
    // @dev NEXT UP => build administrable up from another one... or just from an old Idea
    function build(address _idea, address _creator) public returns(address) {
        return new Administrable(_idea, _creator);
    }

    /// @notice Returns a boolean stating if a given permit is valid/exists or not.
    /// @param permitName The name of the permit to be checked for.
    function isValidPermit(string permitName) public pure returns(bool) {
        switch (permitName) {
            case "issueDividend":
                return true;
            case "dissolveDividend":
                return true;
            case "manageBank":
                return true;
            case "liquidizeEntity":
                return true;
            default:
                return false;
        }
    }

    /// @notice Returns a boolean stating if a given Bank exists.
    /// @param bankName The name of the Bank to be checked for.
    function bankExists(string bankName) public view returns(bool) {
        return validBanks[bankByName[bankName]] == true;
    }

    /// @notice Returns a boolean stating if a given Bank is empty.
    /// @param bankName The name of the Bank to be checked for.
    function bankIsEmpty(string bankName) public view returns(bool) {
        Bank memory bank = bankByName[bankName];
        return bank.storedTokenAddresses == 0 && bank.balance[address(0)] == 0;
    }
    
    /// @notice Returns a boolean stating if a given Dividend exists.
    /// @param dividend The Dividend to be checked for.
    function dividendExists(Dividend dividend) public view returns(bool) {
      return validDividends[dividend] == true;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given bank.
    /// @param _address The address to be checked for.
    /// @param bankName The name of the Bank to be checked for.
    function isBankAdmin(address _address, string bankName) public view returns(bool) {
        return bankByName[bankName].isAdmin[_address] == true || isPermitAdmin(_address,"manageBank");
    }

    /// @notice Returns a boolean stating if a given address has a given permit or not.
    /// @param _address The address to be checked for.
    /// @param permitName The name of the permit to be checked for.
    function hasPermit(address _address, string permitName) public view returns(bool) {
        if (_address == this.address) {return true}
        if (!(isShardHolder(_address) || allowNonShardHolders)) {return false}
        return permits[permitName][_address] >= PermitState.authorized || basePermits.issueVote >= PermitState.authorized;
    }

    /// @notice Returns a boolean stating if a given address is an admin of a given permit or not.
    /// @param _address The address to be checked for.
    /// @param permitName The name of the permit to be checked for.
    function isPermitAdmin(address _address, string permitName) public view returns(bool) {
        if (_address == this.address) {return true}
        if (!(isShardHolder(_address) || allowNonShardHolders)) {return false}
        return permits[permitName][_address] == PermitState.administrator || basePermits.issueVote == PermitState.administrator;
    }

    /// @notice Returns true. Used for differentiating between Administrable and non-Administrable contracts.
    function isAdministrable() constant pure returns(bool) {
        return true;
    }
    
    /// @notice Changes the state of a specified permit of a given address.
    /// @param _address The address, whose permit state is to be changed.
    /// @param permitName The name of the permit, whose state is to be changed.
    /// @param newState The new Permit State to be applied.
    /// @param by The initiator of the permit state change.
    function _changePermit(address _address, string permitName, PermitState newState, address by) internal onlyIfActive {
        require(isValidPermit(permitName), "The given permit name does NOT exist!");
        require(isShardHolder(_address) || allowNonShardHolders, "Only Shard holders can have Permits");
        require(!(hasPermit(_address, permitName) && newState >= PermitState.authorized), "Address already has Permit '" + permitName + "'");
        permits[permitName][_address] = newState;
        emit PermitChanged(_address,permitName,newState,by);
    }

    /// @notice Creates a new Bank.
    /// @param bankName The name of the Bank to be created.
    /// @param bankAdmin The address of the first Bank administrator.
    /// @param by The initiator of the Bank creation.
    function _createBank(string bankName, address bankAdmin, address by) internal onlyIfActive {
        require(!bankExists(bankName), "Bank '"+bankName+"' already exists!");
        require(isShardHolder(bankAdmin) || allowNonShardHolders, "Only Shard holders can be Bank Administrators!");
        require(hasPermit(bankAdmin,"manageBank"),"Only holders of the 'manageBank' Permit can be Bank Administrators!");
        Bank memory bank = new Bank();
        bank.name = bankName;
        bank.isAdmin[bankAdmin] = true;
        validBanks[bank] = true;
        emit BankCreated(bankName,bankAdmin,by);
    }

    /// @notice Adds a new given administrator to a given Bank.
    /// @param bankName The name of the Bank to which the new administrator is to be added.
    /// @param bankAdmin The address of the new Bank administrator to be added.
    /// @param by The initiator of the Bank administrator addition.
    function _addBankAdmin(string bankName, address bankAdmin, address by) internal onlyIfActive {
        require(isBankAdmin(by,bankName))
        require(isShardHolder(bankAdmin) || allowNonShardHolders, "Only Shard holders can be Bank Administrators!");
        require(hasPermit(bankAdmin,"manageBank"),"Only holders of the 'manageBank' Permit can be Bank Administrators!");
        Bank memory bank = bankByName[bankName];
        bank.isAdmin[bankAdmin] = true;
        emit BankAdminAdded(bankName,bankAdmin,by);
    }

    /// @notice Removes a given administrator of a given Bank.
    /// @param bankName The name of the Bank from which the given administrator is to be removed.
    /// @param bankAdmin The address of the current Bank administrator to be removed.
    /// @param by The initiator of the Bank Administrator removal.
    function _removeBankAdmin(string bankName, address bankAdmin, address by) internal onlyIfActive {
        require(isBankAdmin(bankAdmin,bankName));
        require(isShardHolder(bankAdmin) || allowNonShardHolders, "Only Shard holders can be Bank Administrators!");
        require(isPermitAdmin(by,"manageBank"),"Only admins of the 'manageBank' Permit can remove Bank Administrators!");
        Bank memory bank = bankByName[bankName];
        bank.isAdmin[bankAdmin] = false;
        emit BankAdminRemoved(bankName,bankAdmin,by);
    }

    /// @notice Deletes a given Bank.
    /// @param bankName The name of the Bank to be deleted.
    /// @param by The initiator of the Bank deletion.
    function _deleteBank(string bankName, address by) internal onlyIfActive {
        require(bankName != "main", "Can't delete the main bank!");
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exists!");
        require(bankIsEmpty(bankName), "Bank '"+bankName+"' must be empty before being deleted!");
        Bank memory bank = bankByName[bankName];
        validBanks[bank] = false;
        emit BankDeleted(bankName, by);
    }

    /// @notice Creates and issues a Dividend (to all current shareholders) of a token amount from a given Bank.
    /// @param bankName The name of the Bank to issue the Dividend from.
    /// @param tokenAddress The address of the token to make up the Dividend.
    /// @param value The value/amount of the token to be issued in the Dividend.
    /// @param by The initiator of the Dividend issuance.
    function _issueDividend(string bankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(bankName) {
        Bank memory bank = bankByName[bankName];
        require(block.timestamp > latestDividend.creationTime, "Dividends must be issued at least one second between each other.");
        require(value <= bank.balance[tokenAddress], "Dividend value "+string(value)+" can't be more than bank value "+bank.balance[tokenAddress]);
        bank.balance[tokenAddress] -= value;
        if (bank.balance[tokenAddress] == 0) {
            toBank.storedTokenAddresses -= 1;
        }
        Dividend dividend = new Dividend();
        dividend.creationTime = block.timestamp;
        dividend.tokenAddress = tokenAddress;
        dividend.originalValue = value;
        dividend.value = value; 
        validDividends[dividend] = true;
        latestDividend = dividend;
        emit DividendIssued(dividend, by);
    }

    /// @notice Dissolves a Dividend and moves its last contents to the 'main' Bank.
    /// @param dividend The Dividend to be dissolved.
    /// @param by The initiator of the dissolution.
    function _dissolveDividend(Dividend dividend, address by) internal onlyIfActive {
        validDividends[dividend] = false; // -1 to distinguish between empty values;
        uint256 memory valueLeft = dividend.value;
        dividend.value = 0;
        bankByName["main"].balance[dividend.tokenAddress] += valueLeft;
        emit DividendDissolved(dividend, valueLeft, by);
    }

    /// @notice Transfers a token from a Bank to a recipient.
    /// @param fromBankName The name of the Bank from which the token is to be transferred.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    /// @param by The initiator of the transfer.
    function _transferTokenFromBank(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        Bank memory fromBank = bankByName[fromBankName];
        require(value <= fromBank.balance[tokenAddress], "The value transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.balance[tokenAddress]);
        idea.transferToken_(tokenAddress,value,to);
        _processTokenTransfer(fromBank,tokenAddress,value,to,by);
    }

    /// @notice Internally moves a token from one Bank to another.
    /// @param fromBankName The name of the Bank from which the token is to be moved.
    /// @param toBankName The name of the Bank to which the token is to be moved.
    /// @param tokenAddress The address of the token to be moved.
    /// @param value The value/amount of the token to be moved.
    /// @param by The initiator of the move.
    function _moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) onlyIfActive {
        Bank memory fromBank = bankByName[fromBankName];
        Bank memory toBank = bankByName[toBankName];
        require(value <= fromBankName.balance[tokenAddress], "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBank.balance[tokenAddress]);
        fromBank.balance[tokenAddress] -= value;
        if (fromBank.balance[tokenAddress] == 0) {
            fromBank.storedTokenAddresses -= 1;

        }
        if (toBank.balance[tokenAddress] == 0) {
            toBank.storedTokenAddresses += 1;
        }
        toBank.balance[tokenAddress] += value;
        emit TokenMoved(fromBankName,toBankName,tokenAddress,value,by);
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize(address by) internal {
        idea.liquidize_();
    }

    /// @notice Transfers a token from the Idea to a recipient.
    /// @param tokenAddress The address of the token to be transferred.
    /// @param value The value/amount of the token to be transferred.
    /// @param to The recipient of the token to be transferred.
    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        idea.transferToken(tokenAddress,value,to);
    }

    /// @notice Keeps track of a token receipt by adding it to the registry
    /// @param tokenAddress The address of the received token.
    /// @param value The value/amount of the received token.
    /// @param from The sender of the received token.
    function _processTokenReceipt(address tokenAddress, uint256 value, address from) internal {
        // Then: Bank logic
        Bank memory bank = bankByName["main"];
        if (bank.balance[tokenAddress] == 0 && tokenAddress != address(0)) {
            bank.storedTokenAddresses += 1;
        }
        bank.balance[tokenAddress] += value;
        emit TokenReceived(tokenAddress,value,from);
    }

    /// @notice Keeps track of a token transfer and subtracts it from the registry.
    /// @param fromBankName The name of the Bank from which the token is transferred.
    /// @param tokenAddress The address of the transferred token.
    /// @param value The value/amount of the transferred token.
    /// @param to The recipient of the transferred token.
    /// @param by The initiator of the transfer.
    function _processTokenTransfer(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        Bank memory fromBank = bankByName[fromBankName];
        fromBank.balance[tokenAddress] -= value;
        if (fromBank.balance[tokenAddress] == 0) {
            fromBank.storedTokenAddresses[tokenAddress] -= 1;
        }
        emit TokenTransfered(fromBankName,tokenAddress,value,to,by);
    }

}