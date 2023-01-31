pragma solidity ^0.8.4;

import "../shardable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";

/// @title A fractional DAO-like non-fungible token that can be administered by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administerable business entity. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev About to figure out how to do the structure of Proposals right - it can't just be about permits
/// @custom:beaware This is a commercial contract.
contract Administerable is Shardable, ERC20Holder {
    
    constructor() public {
        _createBank("main",msg.sender);
        permits[msg.sender] = Permits(true,true,true,true,true,true,true,true);

    }

    // Banks
    Bank[] banks;
    mapping(Bank => uint256) bankIndex; // starts from 1 and up to keep consistency
    mapping(string => Bank) bankByName;

    // Permits
    mapping(address => Permits) permits;
    Permits basePermits;

    // Pending Referendums
    Referendum[] internal pendingReferendums;
    mapping(Referendum => uint256) pendingReferendumIndex; // starts from 1 and up, to differentiate betweeen empty values

    // Referendums To Be Implemented
    Referendum[] referendumsToBeImplemented;
    mapping(Referendum => uint256) referendumToBeImplementedIndex; // starts from 1 and up, to differentiate betweeen empty values

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

    /// @dev The structures from Permits all the way down to Proposal should be rethought and remade.
    struct Permits {

        // Issue Vote
        bool issueVote; // Permission to issue a vote
        bool administrateIssueVotePermit; // Permission to distribute and withdraw the permit to issue a vote.

        // Issue Dividend
        bool issueDividend;
        bool administrateIssueDividendPermit; // Permission to distribute and withdraw the permit to issue a dividend.

        // Dissolve Dividend
        bool dissolveDividend;
        bool administrateDissolveDividendPermit; // Permission to distribute and withdraw the permit to dissolve a dividend.

        // Manage Bank
        bool manageBank;
        bool administrateManageBankPermit; // Permission to distribute and withdraw the permit to manage a bank.

        // Implement Proposal
        bool implementProposal; // Permission to implement a proposal from a referendum which is to be implemented.
        bool administrateImplementProposal;

        // Liquidize Entity
        bool liquidizeEntity;
        bool administrateLiquidizeEntityPermit;

    }

    struct Proposal {
        string program;
    }

    struct Argument {

    }

    struct Referendum {
        Proposal[] proposals;
        mapping(Proposal => uint256) proposalIndex;
        Fraction forFraction;
        Fraction againstFraction;
        mapping(Shard => bool) hasVoted;
    }

    struct Dividend {
        address tokenAddress;
        uint256 value;
        uint256 originalValue;
        mapping(Shard => bool) applicable;
    }

    // triggers when a dividend is issued
    event DividendIssued(
        Dividend dividend
        );

    // triggers when a dividend is dissolved
    event DividendDissolved(
        Dividend dividend,
        uint256 valueLeft
        );

    // triggers when a dividend is claimed
    event DividendClaimed(
        Dividend dividend,
        address by
        );

    // triggers when a referendum is issued
    event ReferendumIssued(
        Referendum referendum,
        address by
        );

    // triggers when a referendum is closed
    event ReferendumClosed(
        Referendum referendum,
        bool result
        );
        
    event ProposalImplemented(
      Proposal proposal,
      Referendum referendum
      );

    // triggers when a vote is cast
    event VoteCast(
        address by,
        Referendum referendum,
        Shard shard,
        bool for
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

    event BankDeleted(
        string name,
        address by
        );

    event AdministerableLiquidized();

    // triggers when a liquid is claimed
    event LiquidClaimed(
        uint256 value,
        address by
        );

    // modifier to make sure msg.sender has specific permit
    modifier onlyWithPermit(string permitName) {
        require(hasPermit(msg.sender, permitName));
    }

    // modifier to make sure msg.sender has NOT voted on a specific referendum
    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    // modifier to make sure msg.sender is administrator of a specific bank
    modifier onlyBankAdministrator(string bankName) {
        require(isBankAdministrator(msg.sender, bankName));
    }

    // modifier to make sure bank exists
    modifier onlyExistingBank(string bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exist.");
    }

    // modifier to make sure referendum exists
    modifier onlyExistingReferendum(Referendum referendum) {
        require(referendumExists(referendum), "Referendum doesn't exist.");
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
        _issueDividend(bankName,tokenAddress,value);
    }

    /// @notice Dissolves a dividend, releasing its remaining unclaimed value to the 'main' bank.
    /// @param dividend The dividend to be dissolved.
    function dissolveDividend(Dividend dividend) external onlyWithPermit("dissolveDividend") onlyExistingDividend onlyIfActive {
        _dissolveDividend(dividend);
    }

    /// @notice Creates a Bank - a container of funds with access limited to its administators.
    /// @param bankName The name of the Bank to be created
    function createBank(string bankName) external onlyWithPermit("manageBank") {
       _createBank(bankName, msg.sender);
    }

    /// @notice Deletes an empty Bank 
    /// @param bankName The name of the Bank to be deleted
    function deleteBank(string bankName) external onlyWithPermit("manageBank") onlyBankAdministrator(bankName) {
        _deleteBank(bankName);
    }

    /// @notice Moves money internally from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param toBankName The name of the Bank to move the money to.
    /// @param tokenAddress The address of the token to be moved (address(0) if ether)
    /// @param value The value to be moved
    function moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value) external onlyBankAdministrator(fromBankName) {
        _moveToken(fromBankName,bankTo,tokenAddress,value,msg.sender);
    }

    /// @notice Transfers value from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param tokenAddress The address of the token contract (address(0) if ether)
    /// @param toBankName The name of the Bank to move the money to.
    /// @param value The value to be moved
    function transferToken(string fromBankName, address tokenAddress, uint256 value, address to) external onlyBankAdministrator(bankName) {
        _transferToken(fromBankName,tokenAddress,value,to,msg.sender);
    }

    function receiveEther(string bankName) external payable onlyIfActive {
        _processReceipt(bankByName[bankName],msg.value, msg.sender);
    }

    function receiveToken(string bankName, address tokenAddress, uint256 value) external {
        ERC20 token = ERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), value), "Failed to transfer tokens. Make sure the transfer is approved.");
        _processTokenReceipt(bankName,tokenAddress,value,msg.sender);
    }

    function issueVote(Proposal[] proposals) external onlyWithPermit("issueVote") {
        _issueVote(proposals);
    }

    function implementProposal(Referendum referendum, Proposal proposal) external onlyWithPermit("implementProposal") {
        _implementProposal(referendum, proposal);
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    /// @inheritdoc _liquidize
    function liquidize() external onlyWithPermit("liquidizeEntity") {
        _liquidize();
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param referendum The referendum to be voted on.
    /// @param for The boolean value signalling a for or against vote.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the right of the new shard to vote may unfairly perish, possibly making a referendum unsolvable.
    function vote(Referendum referendum, bool for) external onlyShardHolder hasNotVoted(referendum) onlyIfActive {
        Shard memory _shard = shardByOwner[msg.sender];
        if (for) {
            referendum.forFraction = simplifyFraction(addFractions(referendum.forFraction,_shard.fraction));
        }
        else {
            referendum.againstFraction = simplifyFraction(addFractions(referendum.againstFraction,_shard.fraction));
        }
        referendum.hasVoted[_shard] = true;
        emit VoteCast(msg.sender, referendum, _shard, for);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param dividend The dividend to be claimed.
    /// @inheritdoc issueDividend
    function claimDividend(Dividend dividend) external onlyShardHolder onlyExistingDividend onlyIfActive {
        require(active == true, "Can't claim dividends from a liquidized entity. Check liquidization instead.")
        require(dividend.applicable[msg.sender] == true, "Not applicable for Dividend");
        dividend.applicable[msg.sender] = false;
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
        require(tokenAddressIndex[tokenAddress] != 0, "Liquid doesn't contain token with address '"+string(tokenAddress)+"'");
        Dividend tokenLiquidization = liquidization[tokenAddress];
        if (tokenLiquidization.originalValue == tokenLiquidization.value) {
            tokenLiquidization.applicable = validShards;
        }
        require(tokenLiquidization.applicable[msg.sender] == true, "Not applicable for liquidity.");
        tokenLiquidization.applicable[msg.sender] = false;
        liquidValue = shardByOwner[msg.sender].getDecimal() * tokenLiquidization.originalValue;
        tokenLiquidization.value -= liquidValue;
        if (tokenLiquidization.value == 0) {
            tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1];
            tokenAddressIndex[tokenAddress] = 0;
            tokenAddress.pop();
        }
        _transferToken(tokenAddress,liquidValue,msg.sender);
        emit LiquidClaimed(liquidValue,msg.sender);
    }

    function changePermit(address shardHolder, string permitName, bool newState) onlyIfActive {
        require(isShardHolder(shardHolder), "Only Shard holders can have Permits");
        require(!(hasPermit(shardHolder, permitName) & newState == true), "Shard Holder already has Permit '"+permitName+"'");
        switch (permitName) {
                    case "issueVote":
                        require(hasPermit(msg.sender, "administrateIssueVotePermit"));
                        require(!hasPermit(shardHolder, "administrateIssueVotePermit"));
                        permits[shardHolder].issueVote = newState;
                        break;
                    case "administrateIssueVotePermit":
                        require(hasPermit(msg.sender, "administrateIssueVotePermit"));
                        require(!hasPermit(shardHolder, "administrateIssueVotePermit"));
                        permits[shardHolder].administrateIssueVotePermit = true;
                        break;
                    case "issueDividend":
                        require(hasPermit(msg.sender, "administrateIssueDividendPermit"));
                        require(!hasPermit(shardHolder, "administrateIssueDividendPermit"));
                        permits[shardHolder].issueDividend = true;
                        break;
                    case "dissolveDividend":
                        require(hasPermit(msg.sender, "administrateDissolveDividendPermit"));
                        require(!hasPermit(shardHolder, "administrateDissolveDividendPermit"));
                        permits[shardHolder].issueDividend = true;
                        break;
                    case "administrateIssueDividendPermit":
                        require(hasPermit(msg.sender, "administrateIssueDividendPermit"));
                        require(!hasPermit(shardHolder, "administrateIssueDividendPermit"));
                        permits[shardHolder].administrateIssueDividendPermit = true;
                        break;
                    case "manageBank":
                        require(hasPermit(msg.sender, "administrateManageBankPermit"));
                        require(!hasPermit(shardHolder, "administrateManageBankPermit"));
                        permits[shardHolder].manageBank = true;
                        break;
                    case "administrateManageBankPermit":
                        require(hasPermit(msg.sender, "administrateManageBankPermit"));
                        require(!hasPermit(shardHolder, "administrateManageBankPermit"));
                        permits[shardHolder].administrateManageBankPermit = true;
                        break;
                    case "implementProposal":
                        require(hasPermit(msg.sender, "administrateImplementProposal"));
                        require(!hasPermit(shardHolder, "administrateImplementProposal"));
                        permits[shardHolder].implementProposal = true;
                    case "administrateImplementProposal":
                        require(hasPermit(msg.sender, "administrateImplementProposal"));
                        require(!hasPermit(shardHolder, "administrateImplementProposal"));
                        permits[shardHolder].administrateImplementProposal = true;
                    default:
                        revert();
                }
    }

    function hasVoted(address _shardHolder, Referendum referendum) view returns(bool) {
        return referendum.hasVoted[shardByOwner[_shardholder]];
    }

    function bankExists(string bankName) returns(bool) {
        return bankByName[bankName].administrators.length >= 1;
    }

    function bankIsEmpty(string bankName) returns(bool) {
        Bank memory bank = bankByName[bankName];
        return bank.tokenAddresses.length == 0 && bank.balance[address(0)] == 0;
    }

    function referendumExists(Referendum referendum) returns(bool) {
        return referendumIndex[referendum] > 0; // bigger than 0 because stored indices start from 1
    }
    
    function dividendExists(Dividend dividend) view returns(bool) {
      return dividendIndex[dividend] > 0; ; // bigger than 0 because stored indices starts from 1
    }

    function isBankAdministrator(address _administrator, string bankName) view returns(bool) {
        return bankByName[bankName].administratorIndex[_administrator] != 0;
    }


    function getReferendumResult(Referendum referendum) pure returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if (referendum.forFraction.numerator / referendum.forFraction.denominator > 0.5) {
            return true;
        }
        return false;
    }

    function hasPermit(address holder, string permitName) view returns (bool) {
        switch (permitName) {
                    case "issueVote":
                        return permits[holder].issueVote || basePermits.issueVote;
                    case "administrateIssueVotePermit":
                        return permits[holder].administrateIssueVotePermit || basePermits.administrateIssueVotePermit;
                    case "issueDividend":
                        return permits[holder].issueDividend || basePermits.issueDividend;
                    case "dissolveDividend":
                        return permits[holder].dissolveDividend || basePermits.dissolveDividend;
                    case "administrateIssueDividendPermit":
                        return permits[holder].administrateIssueDividendPermit || basePermits.administrateIssueDividendPermit;
                    case "manageBank":
                        return permits[holder].manageBank || basePermits.administrateManageBankPermit;
                    case "administrateManageBankPermit":
                        return permits[holder].administrateManageBankPermit || basePermits.administrateManageBankPermit;
                    case "implementProposal":
                        return permits[holder].implementProposal || basePermits.implementProposal;
                    case "administrateImplementProposal":
                        return permits[holder].administrateImplementProposal || basePermits.administrateImplementProposal;
                    default:
                        revert();
                }
    }

    /// @notice Liquidizes and dissolves the administerable entity. This cannot be undone.
    function _liquidize() internal {
        active = false; // stops trading of Shards
        liquidization = new Dividend(address(this).balance, validShards); // sets up a final dividend for shardholders
        emit AdministerableLiquidized();
    }

    function _moveToken(string fromBankName, string toBankName, address tokenAddress, uint256 value, address by) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) onlyIfActive {
        Bank memory fromBank = bankByName[fromBankName];
        Bank memory toBank = bankByName[toBankName];
        require(value <= fromBankName.balance[tokenAddress], "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBank.balance[tokenAddress]);
        bankFrom.balance[tokenAddress] -= value;
        bankTo.balance[tokenAddress] += value;
        emit TokenMoved(fromBankName,toBankName,tokenAddress,value,by);
    }

    function _transferEther(string fromBankName, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        require(value <= fromBank.balance[address(0)], "The value transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.balance[address(0)]);
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }

    function _transferToken(address tokenAddress, uint256 value, address to) internal {
        if (tokenAddress == address(0)) { _transferEther(value, to, by);}
        else {
            ERC20 token = ERC20(tokenAddress);
            require(token.approve(to, value), "Failed to approve transfer");
            to.receiveToken(tokenAddress,value);
        }
    }

    function _transferTokenFromBank(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        Bank memory fromBank = bankByName[fromBankName];
        require(value <= fromBank.balance[tokenAddress], "The value transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.balance[tokenAddress]);
        _transferToken(tokenAddress,value,to);
        _processTokenTransfer(fromBank,tokenAddress,value,to,by);
    }

    function _processTokenTransfer(string fromBankName, address tokenAddress, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        // First: Liquidization logic
        liquidization[tokenAddress].originalValue -= value;
        if (liquidization[tokenAddress].originalValue == 0) {
            tokenAddresses[tokenAddressIndex[tokenAddress]-1] = tokenAddresses[tokenAddresses.length-1];
            tokenAddressIndex[tokenAddress] = 0;
            tokenAddress.pop();
        }
        // Then: Bank logic
        Bank memory fromBank = bankByName[fromBankName];
        fromBank.balance[tokenAddress] -= value;
        if (bank.balance[tokenAddress] == 0) {
            bank.tokenAddresses[bank.tokenAddressIndex[tokenAddress]-1] = bank.tokenAddresses[bank.tokenAddresses.length-1];
            bank.tokenAddressIndex[tokenAddress] = 0;
            bank.tokenAddresses.pop();
        }
        emit TokenTransfered(fromBankName,tokenAddress,value,to,by);
    }

    function _processTokenReceipt(string bankName, address tokenAddress, uint256 value, address from) internal onlyExistingBank(toBankName) {
        // First: Liquidization logic
        if (tokenAddressIndex[tokenAddress] != 0) {
            tokenAddressIndex[tokenAddress] = tokenAddresses.length + 1;
            tokenAddresses.push(tokenAddress);
            Dividend newDividend = new Dividend();
            newDividend.tokenAddress = tokenAddress;
            newDividend.originalValue = value;
            liquidization[tokenAddress] = newDividend;
        }
        else {
            liquidization[tokenAddress].originalValue += value;
        }
        // Then: Bank logic
        Bank memory bank = bankByName[bankName];
        if (bank.balance[tokenAddress] == 0 && tokenAddress != address(0)) {
            bank.tokenAddressIndex[tokenAddress] = bank.tokenAddresses.length + 1;
            bank.tokenAddresses.push(tokenAddress);
        }
        bank.balance[tokenAddress] += value;
        emit TokenReceived(bankName,tokenAddress,value,from);
    }

    function _createBank(string bankName, address bankAdministrator) internal onlyIfActive {
        require(!bankExists(bankName), "Bank '"+bankName+"' already exists!");
        Bank memory bank = new Bank();
        bank.administrators.push(bankAdministrator);
        bank.administratorIndex[bankAdministrator] = 1;
        bankIndex[bank] = banks.length+1; // +1 because stored indices starts from 1
        banks.push(bank);
        emit BankCreated(bankName,bankAdministrator);
    }

    function _deleteBank(string bankName) internal onlyIfActive {
        require(bankName != "main", "Can't delete the main bank!");
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exists!");
        require(bankIsEmpty(bankName), "Bank '"+bankName+"' must be empty before being deleted!");
        Bank memory bank = bankByName[bankName];
        banks[bankIndex[bank]] = banks[banks.length-1]; // -1 because stored indices starts from 1
        banks.pop();
        bankByName[bankName] = new Bank();
        emit BankDeleted(bankName);
    }

    function _issueVote(Proposal[] proposals, address by) internal onlyIfActive {
        Referendum referendum = new Referendum(proposals);
        pendingReferendumIndex[referendum] = pendingReferendums.length+1; // +1 to distinguish between empty values
        pendingReferendums.push(referendum);
        emit ReferendumIssued(referendum, by);
    }

    function _issueDividend(string bankName, address tokenAddress, uint256 value) internal onlyExistingBank(bankName) {
        Bank memory bank = bankByName[bankName];
        require(value <= bank.balance[tokenAddress], "Dividend value "+string(value)+" can't be more than bank value "+bank.balance[tokenAddress]);
        bank.balance[tokenAddress] -= value;
        Dividend newDividend = new Dividend();
        newDividend.tokenAddress = tokenAddress;
        newDividend.originalValue = value;
        newDividend.value = value; 
        newDividend.applicable = validShards;
        dividendIndex[dividend] = dividends.lenght+1; // +1 to distinguish between empty values;
        dividends.push(newDividend);
        emit DividendIssued(newDividend);
    }

    function _dissolveDividend(Dividend dividend) internal onlyIfActive {
        dividends[dividendIndex[dividend]] = dividends[dividends.lenght-1];
        dividends.pop();
        uint256 memory valueLeft = dividend.value;
        dividend.value = 0;
        bankByName["main"].balance[dividend.tokenAddress] += valueLeft;
        emit DividendDissolved(dividend, valueLeft);
    }

    function _closeReferendum(Referendum referendum) internal onlyExistingReferendum(referendum) onlyIfActive {
        bool memory result = getReferendumResult(referendum);
        // remove the now closed Referendum from 'pendingReferendums'
        pendingReferendums[pendingReferendumIndex[referendum]-1] = pendingReferendums[pendingReferendums.length]; // -1 because stored indices starts from 1
        pendingReferendumIndex[referendum] = 0; // a stored index value of 0 means empty
        pendingReferendums.pop()

        if (result) { // if it got voted through
            // the proposals are pushed to 'proposalsToBeImplemented'
            proposalsToBeImplemented.push(referendum.proposals);
        }
        emit ReferendumClosed(referendum, result);
    }

    function _implementProposal(Referendum referendum, Proposal proposal) internal onlyIfActive {
        require(referendumToBeImplementedIndex[referendum]>0);
        require(referendum.proposalIndex[proposal]>0);
        this.call(bytes4(sha3(proposal.program)));
        referendum.proposals[referendum.proposalIndex[proposal]-1] =referendum.proposals[referendum.proposals.length];
        referendum.proposals.pop();
        if (referendum.proposals.length==0) {
          // remove fully implemented referendum from referendumsToBeImplemented
          referendumsToBeImplemented[referendumToBeImplementedIndex[referendum]] = referendumsToBeImplemented[referendumToBeImplemented.length];
          referendumToBeImplemented.pop();
        }
    }

}