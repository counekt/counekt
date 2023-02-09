pragma solidity ^0.8.4;

import "../shardable.sol";

/// @title A fractional DAO-like contract that through permits, banks and dividends can be administered by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administerable business entity. 
/// @custom:beaware This is a commercial contract.
contract Administerable is Shardable {
    
    function initialize() reinitializer(2) public {
        _createBank("main",msg.sender,this.address);
        // First Shard holder is initialized with all Permits
        PermitSet permitSet = PermitSet();
        permitSet.issueVote = PermitState.administrator;
        permitSet.issueDividend = PermitState.administrator;
        permitSet.dissolveDividend = PermitState.administrator;
        permitSet.manageBank = PermitState.administrator;
        permitSet.implementProposal = PermitState.administrator;
        permitSet.liquidizeEntity = PermitState.administrator;
        permits[msg.sender] = permitSet;
    }

    // Rules
    /// @notice Rules that lay the ground for the fundamental logic of the entity. 
    // @dev To be implemented. And next up: voting thresholds.
    bool allowNonShardHolders;

    // Banks
    Bank[] banks;
    mapping(Bank => uint256) bankIndex; // starts from 1 and up to keep consistency
    mapping(string => Bank) bankByName;

    // Permits
    mapping(address => PermitSet) permits;
    PermitSet basePermits;

    // Dividends
    Dividend[] internal dividends;
    mapping(Dividend => uint256) dividendIndex; // starts from 1 and up, to differentiate betweeen empty values

    // Liquidization (in case of dissolvement of the administerable entity) - Dividends by token addresses
    // is updated along the way
    mapping(address => Dividend) liquidization;
    address[] tokenAddresses;
    mapping(address => uint256) tokenAddressIndex; // starts from 1 and up, to differentiate betweeen empty values

    struct Bank {
        address[] tokenAddresses;
        mapping(address => uint256) tokenAddressIndex;
        mapping(address => uint256) balance;
        address[] administrators;
        mapping(address => uint256) administratorIndex;
    }

    enum PermitState {
        unauthorized,
        authorized,
        administrator
    }

    struct PermitSet {
        // Issue Vote
        PermitState issueVote; // Permission to issue a vote

        // Issue Dividend
        PermitState issueDividend;

        // Dissolve Dividend
        PermitState dissolveDividend;

        // Manage Bank
        PermitState manageBank;

        // Implement Proposal
        PermitState implementProposal; // Permission to implement a proposal from a referendum which is to be implemented.

        // Liquidize Entity
        PermitState liquidizeEntity;
    }

    struct Dividend {
        uint256 creationTime;
        address tokenAddress;
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) hasClaimed;
    }

    // triggers when a dividend is issued
    event DividendIssued(
        Dividend dividend,
        address by
    );

    // triggers when a dividend is dissolved
    event DividendDissolved(
        Dividend dividend,
        uint256 valueLeft,
        address by
    );

    // triggers when a dividend is claimed
    event DividendClaimed(
        Dividend dividend,
        address by
    );

    // triggers when money is received
    event TokenReceived(
        string bankName,
        address tokenAddress,
        uint256 value,
        address from
    );

    // triggers when token is transferred
    event TokenTransfered(
        string bankName,
        address tokenAddress,
        uint256 value,
        address to,
        address by
    );

    // triggers when a token is moved from one bank to another
    event TokenMoved(
        string fromBankName,
        string toBankName,
        address tokenAddress,
        uint256 value,
        address by
    );

    // triggers when bank is created
    event BankCreated(
        string name,
        address by
    );


    // triggers when a bank is deleted
    event BankDeleted(
        string name,
        address by
    );

    // triggers when the entity is liquidized
    event EntityLiquidized(address by);

    // triggers when a liquid is claimed
    event LiquidClaimed(
        uint256 value,
        address by
    );

    // modifier to make sure msg.sender has specific permit
    modifier onlyWithPermit(string permitName) {
        require(hasPermit(msg.sender, permitName));
    }

    // modifier to make sure msg.sender is administrator of a specific bank
    modifier onlyBankAdministrator(string bankName) {
        require(isBankAdministrator(msg.sender, bankName));
    }

    // modifier to make sure bank exists
    modifier onlyExistingBank(string bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' does NOT exist!");
    }
    
    // modifier to make sure dividend exists
    modifier onlyExistingDividend(Dividend dividend) {
      require(dividendExists(dividend));
    }

    // modifier to make sure entity is active and not liquidized/dissolved
    modifier onlyIfActive() {
        require(active == true, "Administerable entity isn't active.");
    }

    /// @notice Receives money when there's no supplying data and puts it into the 'main' bank 
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processTokenReceipt("main",address(0),msg.value,msg.sender);
    }

    /// @notice Issues a dividend to all current shareholders, which they'll have to claim themselves.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the Dividend Right sometimes perishes.
    /// @param bankName The name of the bank to issue a dividend from.
    /// @param value The value of the dividend to be issued.
    function issueDividend(string bankName, address tokenAddress, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdministrator(bankName) onlyIfActive {
        _issueDividend(bankName,tokenAddress,value, msg.sender);
    }

    /// @notice Dissolves a dividend, releasing its remaining unclaimed value to the 'main' bank.
    /// @param dividend The dividend to be dissolved.
    function dissolveDividend(Dividend dividend) external onlyWithPermit("dissolveDividend") onlyExistingDividend onlyIfActive {
        _dissolveDividend(dividend, msg.sender);
    }

    /// @notice Creates a Bank - a container of funds with access limited to its administators.
    /// @param bankName The name of the Bank to be created
    function createBank(string bankName, address bankAdministrator) external onlyWithPermit("manageBank") {
       _createBank(bankName, bankAdministrator, msg.sender);
    }

    /// @notice Deletes an empty Bank 
    /// @param bankName The name of the Bank to be deleted
    function deleteBank(string bankName) external onlyWithPermit("manageBank") onlyBankAdministrator(bankName) {
        _deleteBank(bankName, msg.sender);
    }

    /// @notice Transfers value from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param tokenAddress The address of the token contract (address(0) if ether)
    /// @param toBankName The name of the Bank to move the money to.
    /// @param value The value to be moved
    function transferToken(string fromBankName, address tokenAddress, uint256 value, address to) external onlyBankAdministrator(bankName) {
        _transferToken(fromBankName,tokenAddress,value,to,msg.sender);
    }

    /// @notice Moves money internally from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param toBankName The name of the Bank to move the money to.
    /// @param tokenAddress The address of the token to be moved (address(0) if ether)
    /// @param value The value to be moved
    function moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value) external onlyBankAdministrator(fromBankName) {
        _moveToken(fromBankName,bankTo,tokenAddress,value,msg.sender);
    }

    function receiveToken(string bankName, address tokenAddress, uint256 value) external {
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(bankName,tokenAddress,value,msg.sender);
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    /// @inheritdoc _liquidize
    function liquidize() external onlyWithPermit("liquidizeEntity") {
        _liquidize(msg.sender);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param dividend The dividend to be claimed.
    /// @inheritdoc issueDividend
    /// @dev Now only shards who exist at the time of Dividend creation are applicable. Next up: Must be claimed with reference to shard.
    function claimDividend(Shard shard, Dividend dividend) external onlyExistingDividend onlyIfActive {
        require(active == true, "Can't claim dividends from a liquidized entity! Check liquidization instead.")
        require(isHistoricShard(shard), "Shard must be historic part of Shardable!");
        require(dividend.hasClaimed[msg.sender] == false, "Already claimed Dividend!");
        require(shardExisted(shard,dividend.creationTime), "Not applicable for Dividend!");
        dividend.hasClaimed[msg.sender] = true;
        dividendValue = shardByOwner[msg.sender].getDecimal() * dividend.originalValue;
        dividend.value -= dividendValue;
        _transferToken(dividend.tokenAddress,dividendValue,msg.sender);
        emit DividendClaimed(dividend,dividendValue,msg.sender);
        if (dividend.value == 0) {
            _dissolveDividend(dividend);
        }
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction when the entity has been liquidized/dissolved.
    /// @inheritdoc _liquidize
    /// @dev NOT UP TO DATE WITH THE TOKEN ECOSYSTEM IMPLEMENTATION
    function claimLiquid(address tokenAddress) external onlyShardHolder {
        require(active == false, "Can't claim liquid, when the entity isn't dissolved and liquidized.");
        require(tokenAddressIndex[tokenAddress] > 0, "Liquid doesn't contain token with address '"+string(tokenAddress)+"'");
        Dividend tokenLiquidization = liquidization[tokenAddress];
        
        require(!tokenLiquidization.hasClaimed[msg.sender], "Liquid token'"+string(tokenAddress)+"' already claimed!");
        tokenLiquidization.hasClaimed[msg.sender] = true;
        liquidValue = shardByOwner[msg.sender].getDecimal() * tokenLiquidization.originalValue;
        tokenLiquidization.value -= liquidValue;
        if (tokenLiquidization.value == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        _transferToken(tokenAddress,liquidValue,msg.sender);
        emit LiquidClaimed(liquidValue,msg.sender);
    }

    function changePermit(address shardHolder, string permitName, PermitState newState) onlyIfActive {
        require(isShardHolder(shardHolder) || allowNonShardHolders, "Only Shard holders can have Permits");
        require(!(hasPermit(shardHolder, permitName) && newState >= PermitState.authorized), "Shard Holder already has Permit '"+permitName+"'");
        switch (permitName) {
                    case "issueVote":
                        require(isPermitAdministrator(msg.sender, "issueVote"));
                        require(!isPermitAdministrator(shardHolder, "issueVote"));
                        permits[shardHolder].issueVote = newState;
                        break;
                    case "issueDividend":
                        require(isPermitAdministrator(msg.sender, "issueDividend"));
                        require(!isPermitAdministrator(shardHolder, "issueDividend"));
                        permits[shardHolder].issueDividend = newState;
                        break;
                    case "dissolveDividend":
                        require(isPermitAdministrator(msg.sender, "dissolveDividend"));
                        require(!isPermitAdministrator(shardHolder, "dissolveDividend"));
                        permits[shardHolder].issueDividend = newState;
                        break;
                    case "manageBank":
                        require(isPermitAdministrator(msg.sender, "manageBank"));
                        require(!isPermitAdministrator(shardHolder, "manageBank"));
                        permits[shardHolder].manageBank = newState;
                        break;
                    case "implementProposal":
                        require(isPermitAdministrator(msg.sender, "implementProposal"));
                        require(!isPermitAdministrator(shardHolder, "implementProposal"));
                        permits[shardHolder].implementProposal = newState;
                        break;
                    case "liquidizeEntity":
                        require(isPermitAdministrator(msg.sender, "liquidizeEntity"));
                        require(!isPermitAdministrator(shardHolder, "liquidizeEntity"));
                        permits[shardHolder].liquidizeEntity = newState;
                        break;
                    default:
                        revert();
        }
    }

    /// @dev This fucntion won't work with other contracts inheriting from this - and certainly not with upgradable proxies!
    function isAdministerable(address _address) returns(bool) {
        bytes32 administerableBytecode = bytes32(keccak256(abi.encodePacked(type(Administerable).creationCode)));
        bytes32 targetBytecode = bytes32(keccak256(abi.encodePacked(bytes(_address.code()))));
        return administerableBytecode == targetBytecode;
    }

    function bankExists(string bankName) returns(bool) {
        return bankIndex[bankByName[bankName]] > 0; // bigger than 0 because stored indices starts from 1
    }

    function bankIsEmpty(string bankName) returns(bool) {
        Bank memory bank = bankByName[bankName];
        return bank.tokenAddresses.length == 0 && bank.balance[address(0)] == 0;
    }
    
    function dividendExists(Dividend dividend) view returns(bool) {
      return dividendIndex[dividend] > 0; // bigger than 0 because stored indices starts from 1
    }

    function isBankAdministrator(address _administrator, string bankName) view returns(bool) {
        return bankByName[bankName].administratorIndex[_administrator] > 0 || permits[_administrator].manageBank == PermitState.administrator;
    }

    function hasPermit(address holder, string permitName) view returns(bool) {
        if (holder == this.address) {return true}
        if (!(isShardHolder(holder) || allowNonShardHolders)) {return false}
        switch (permitName) {
                    case "issueVote":
                        return permits[holder].issueVote >= PermitState.authorized || basePermits.issueVote >= PermitState.authorized;
                    case "issueDividend":
                        return permits[holder].issueDividend >= PermitState.authorized || basePermits.issueDividend >= PermitState.authorized;
                    case "dissolveDividend":
                        return permits[holder].dissolveDividend  >= PermitState.authorized || basePermits.dissolveDividend >= PermitState.authorized;
                    case "manageBank":
                        return permits[holder].manageBank >= PermitState.authorized || basePermits.manageBank >= PermitState.authorized;
                    case "implementProposal":
                        return permits[holder].implementProposal >= PermitState.administrator || basePermits.implementProposal >= PermitState.authorized;
                    case "liquidizeEntity":
                        return permits[holder].liquidizeEntity >= PermitState.authorized || basePermits.liquidizeEntity >= PermitState.authorized;
                    default:
                        revert();
        }

    }

    function isPermitAdministrator(address holder, string permitName) view returns(bool) {
        if (holder == this.address) {return true}
        if (!(isShardHolder(holder) || allowNonShardHolders)) {return false}
        switch (permitName) {
                    case "issueVote":
                        return permits[holder].issueVote == PermitState.administrator || basePermits.issueVote == PermitState.administrator;
                    case "issueDividend":
                        return permits[holder].issueDividend == PermitState.administrator || basePermits.issueDividend  == PermitState.administrator;
                    case "dissolveDividend":
                        return permits[holder].dissolveDividend  == PermitState.administrator || basePermits.dissolveDividend  == PermitState.administrator;
                    case "manageBank":
                        return permits[holder].manageBank == PermitState.administrator || basePermits.manageBank == PermitState.administrator;
                    case "implementProposal":
                        return permits[holder].implementProposal == PermitState.administrator || basePermits.implementProposal == PermitState.administrator;
                    case "liquidizeEntity":
                        return permits[holder].liquidizeEntity == PermitState.administrator || basePermits.liquidizeEntity == PermitState.administrator;
                    default:
                        revert();
        }
    }

    function _createBank(string bankName, address bankAdministrator, address by) internal onlyIfActive {
        require(!bankExists(bankName), "Bank '"+bankName+"' already exists!");
        require(isShardHolder(bankAdministrator) || allowNonShardHolders, "Only Shard holders can be Bank Administrators!");
        require(hasPermit(bankAdministrator,"manageBank"),"Only holders of the 'manageBank' Permit can be Bank Administrators!");
        Bank memory bank = new Bank();
        bank.administrators.push(bankAdministrator);
        bank.administratorIndex[bankAdministrator] = 1;
        bankIndex[bank] = banks.length+1; // +1 because stored indices starts from 1
        banks.push(bank);
        emit BankCreated(bankName,bankAdministrator, by);
    }

    function _deleteBank(string bankName, address by) internal onlyIfActive {
        require(bankName != "main", "Can't delete the main bank!");
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exists!");
        require(bankIsEmpty(bankName), "Bank '"+bankName+"' must be empty before being deleted!");
        Bank memory bank = bankByName[bankName];
        banks[bankIndex[bank]-1] = banks[banks.length-1]; // -1 because stored indices starts from 1
        banks.pop();
        bankByName[bankName] = new Bank();
        emit BankDeleted(bankName, by);
    }

    function _issueDividend(string bankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(bankName) {
        Bank memory bank = bankByName[bankName];
        require(value <= bank.balance[tokenAddress], "Dividend value "+string(value)+" can't be more than bank value "+bank.balance[tokenAddress]);
        bank.balance[tokenAddress] -= value;
        Dividend newDividend = new Dividend();
        newDividend.creationTime = block.timestamp;
        newDividend.tokenAddress = tokenAddress;
        newDividend.originalValue = value;
        newDividend.value = value; 
        newDividend.applicable = validShards;
        dividendIndex[dividend] = dividends.lenght+1; // +1 to distinguish between empty values;
        dividends.push(newDividend);
        emit DividendIssued(newDividend, by);
    }

    function _dissolveDividend(Dividend dividend, address by) internal onlyIfActive {
        dividends[dividendIndex[dividend]-1] = dividends[dividends.lenght-1]; // -1 to distinguish between empty values;
        dividends.pop();
        uint256 memory valueLeft = dividend.value;
        dividend.value = 0;
        bankByName["main"].balance[dividend.tokenAddress] += valueLeft;
        emit DividendDissolved(dividend, valueLeft, by);
    }

    function _transferTokenFromBank(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        Bank memory fromBank = bankByName[fromBankName];
        require(value <= fromBank.balance[tokenAddress], "The value transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.balance[tokenAddress]);
        _transferToken(tokenAddress,value,to);
        _processTokenTransfer(fromBank,tokenAddress,value,to,by);
    }

    function _moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) onlyIfActive {
        Bank memory fromBank = bankByName[fromBankName];
        Bank memory toBank = bankByName[toBankName];
        require(value <= fromBankName.balance[tokenAddress], "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBank.balance[tokenAddress]);
        bankFrom.balance[tokenAddress] -= value;
        bankTo.balance[tokenAddress] += value;
        emit TokenMoved(fromBankName,toBankName,tokenAddress,value,by);
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize(address by) internal {
        active = false; // stops trading of Shards
        emit EntityLiquidized(by);
    }

    function _processTokenTransfer(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        // First: Liquidization logic
        liquidization[tokenAddress].originalValue -= value;
        if (liquidization[tokenAddress].originalValue == 0) {
            _unregisterTokenAddress(tokenAddress);
        }
        // Then: Bank logic
        Bank memory fromBank = bankByName[fromBankName];
        fromBank.balance[tokenAddress] -= value;
        if (bank.balance[tokenAddress] == 0) {
            _unregisterTokenAddressFromBank(tokenAddress,bankName);
        }
        emit TokenTransfered(fromBankName,tokenAddress,value,to,by);
    }

    function _processTokenReceipt(string bankName, address tokenAddress, uint256 value, address from) internal onlyExistingBank(toBankName) {
        // First: Liquidization logic
        if (tokenAddressIndex[tokenAddress] != 0) {
            _registerTokenAddress(tokenAddress);
        }
        else {
            liquidization[tokenAddress].originalValue += value;
        }
        // Then: Bank logic
        Bank memory bank = bankByName[bankName];
        if (bank.balance[tokenAddress] == 0 && tokenAddress != address(0)) {
            _registerTokenAddressToBank(tokenAddress);
        }
        bank.balance[tokenAddress] += value;
        emit TokenReceived(bankName,tokenAddress,value,from);
    }

    function _transferEther(uint256 value, address to) internal {
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }

    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) { _transferEther(value, to);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "Failed to approve transfer");
            if (isAdministerable(to)) {
                Administerable(to).receiveToken("main", tokenAddress, value);
            }

        }
    }

    function _registerTokenAddress(address tokenAddress) {
        require(tokenAddressIndex[tokenAddress] == 0, "Token address '"+string(tokenAddress)+"' ALREADY registered!");
        tokenAddressIndex[tokenAddress] = tokenAddresses.length + 1; // +1 to distinguish between empty values;
        tokenAddresses.push(tokenAddress);
        // Update liquidization
        Dividend newDividend = new Dividend();
        newDividend.tokenAddress = tokenAddress;
        newDividend.originalValue = value;
        liquidization[tokenAddress] = newDividend;
    }

    function _registerTokenAddressToBank(address tokenAddress, string bankName) onlyExistingBank(bankName) {
        Bank memory bank = bankByName[bankName];
        require(bank.tokenAddressIndex[tokenAddress] == 0, "Token address '"+string(tokenAddress)+"' ALREADY registered!"); // a stored index value of 0 means empty
        bank.tokenAddressIndex[tokenAddress] = bank.tokenAddresses.length + 1; // +1 to distinguish between empty values;
        bank.tokenAddresses.push(tokenAddress);
    }

    function _unregisterTokenAddress(address tokenAddress) {
        require(tokenAddressIndex[tokenAddress] > 0, "Token address '"+string(tokenAddress)+"' NOT registered!");
        tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1]; // -1 to distinguish between empty values;
        tokenAddressIndex[tokenAddress] = 0; // a stored index value of 0 means empty
        tokenAddress.pop();
    }

    function _unregisterTokenAddressFromBank(address tokenAddress, string bankName) onlyExistingBank(bankName) {
        Bank memory bank = bankByName[bankName];
        require(bank.tokenAddressIndex[tokenAddress] > 0, "Token address '"+string(tokenAddress)+"' NOT registered!");
        bank.tokenAddresses[bank.tokenAddressIndex[tokenAddress]-1] = bank.tokenAddresses[bank.tokenAddresses.length-1]; // -1 to distinguish between empty values;
        bank.tokenAddressIndex[tokenAddress] = 0; // a stored index value of 0 means empty
        bank.tokenAddresses.pop();
    }

}