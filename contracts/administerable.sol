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
    }

    // Bank by name
    Bank[] banks;
    mapping(Bank => uint256) bankIndex; // starts from 1 and up to keep consistency
    mapping(string => Bank) bankByName;

    // mapping of addresses with permits
    mapping(address => Permits) permits;

    // Pending Referendums
    Referendum[] internal pendingReferendums;
    mapping(Referendum => uint256) pendingReferendumIndex; // starts from 1 and up, to differentiate betweeen empty values

    // Proposals
    Referendum[] referendumsToBeImplemented;
    
    // Dividends
    Dividend[] internal dividends;
    mapping(Dividend => uint256) dividendIndex;

    Dividend liquidization;


    struct Bank {
        uint256 balance;
        address[] administrators;
        mapping(address => bool) isAdministrator;
    }

    /// @dev The structures from Permits all the way down to Proposal should be rethought and remade.
    struct Permits {
        // Issue Referendum
        bool issueReferendum; // Permission to issue a Referendum
        bool administrateIssueReferendumPermit; // Permission to distribute and withdraw the permit to issue a Referendum

        // Issue Dividend
        bool issueDividend;
        bool administrateIssueDividendPermit; // Permission to distribute and withdraw the permit to issue a dividend

        // Manage Bank
        bool manageBank;
        bool administrateManageBankPermit; // Permission to distribute and withdraw the permit to manage a bank

        // 

    }

    struct Proposal {
        string program;
    }

    struct Referendum {
        Proposal[] proposals;
        Fraction forFraction;
        Fraction againstFraction;
        mapping(Shard => bool) hasVoted;
    }

    struct Dividend {
        uint256 value;
        mapping(Shard => bool) applicable;
    }

    // triggers when a dividend is issued
    event DividendIssued(
        Dividend dividend,
        uint256 value
        );

    // triggers when a dividend is dissolved
    event DividendDissolved(
        Dividend dividend,
        uint256 value
        );

    // triggers when a dividend is claimed
    event DividendClaimed(
        Dividend dividend,
        uint256 value,
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
        )
        
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
    event MoneyReceived(
        address tokenAddress,
        string bankName,
        uint256 value,
        address from
        );

    // triggers when money is transferred
    event MoneyTransfered(
        address tokenAddress,
        uint256 value,
        string bankName,
        address to,
        address by
        );

    event MoneyMoved(
        string fromBankName,
        string toBankName,
        uint256 value,
        address by
        );

    // triggers when bank is created
    event BankCreated(
        string name,
        address by
        );

    event BankDeleted(
        string name
        )

    event AdministerableDissolved(

        );

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

    modifier onlyExistingBank(string bankName) {
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exist.");
    }

    modifier onlyExistingReferendum(Referendum referendum) {
        require(referendumExists(referendum), "Referendum doesn't exist.");
    }
    
    modifier onlyExistingDividend(Dividend dividend) {
      require(dividendExists(dividend));
    }

    modifier onlyIfActive() {
        require(active == true, "Administerable entity isn't active.");
    }

    /// @notice Receives money when there's no supplying data and puts it into the 'main' bank 
    receive() payable onlyIfActive {
        require(active == true, "Can't transfer anything to a liquidized entity.");
        _processReceipt(bankByName["main"],msg.value,msg.sender);
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

    /// @notice Issues a dividend to all current shareholders, which they'll have to claim themselves.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the Dividend Right sometimes perishes.
    /// @param bankName The name of the bank to issue a dividend from.
    /// @param value The value of the dividend to be issued.
    function issueDividend(string bankName, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdministrator(bankName) onlyIfActive {
        require(value <= bankByName[bankName].value, "Dividend value "+string(value)+" can't be more than bank value "+bank.value);
        bank.value -= value;
        Dividend newDividend = new Dividend(value,validShards);
        dividendIndex[dividend] = dividends.lenght+1; // +1 to distinguish between empty values;
        dividends.push(newDividend);
        emit DividendIssued();
    }

    /// @notice Dissolves a dividend, releasing its remaining unclaimed value to the 'main' bank.
    /// @param dividend The dividend to be dissolved.
    function dissolveDividend(Dividend dividend) external onlyWithPermit("issueDividend") onlyExistingDividend onlyIfActive {
      dividends[dividendIndex[dividend]] = dividends[dividends.lenght-1];
      dividends.pop();
        uint256 memory valueLeft = dividend.value;
        dividend.value = 0;
        bankByName["main"].value += valueLeft;
        emit DividendDissolved(dividend, valueLeft);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param dividend The dividend to be claimed.
    /// @inheritdoc issueDividend
    function claimDividend(Dividend dividend) external onlyShardHolder onlyExistingDividend onlyIfActive{
        require(active == true, "Can't claim dividends from a liquidized entity. Check liquidization instead.")
        require(dividend.applicable[msg.sender] == true, "Not applicable for Dividend");
        dividendValue = shardByOwner[msg.sender].getDecimal() * dividend.value;
        dividend.applicable[msg.sender] = false;
        dividend.value -= dividendValue;
        (bool success, ) = address(msg.sender).call.value(dividendValue)("");
        require(success, "Transfer failed.");
        emit DividendClaimed(dividend,dividendValue,msg.sender);
    }

    /// @notice Claims the owed liquid value corresponding to the shard holder's respective shard fraction when the entity has been liquidized/dissolved.
    /// @inheritdoc _dissolve
    function claimLiquid() external onlyShardHolder {
        require(active == false, "Can't claim liquid, when the entity isn't dissolved and liquidized.")
        require(liquidization.applicable[msg.sender] == true, "Not applicable for liquidity.");
        liquidization.applicable[msg.sender] = false;
        liquidValue = shardByOwner[msg.sender].getDecimal() * address(this).balance;
        (bool success, ) = address(msg.sender).call.value(liquidValue)("");
        require(success, "Transfer failed.");
        emit LiquidClaimed(liquidValue,msg.sender);
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
    /// @param value The value to be moved
    function moveMoney(string fromBankName, string toBankName, uint256 value) external onlyBankAdministrator(fromBankName) {
        _moveMoney(fromBankName,bankTo,value,msg.sender);
    }

    /// @notice Transfers value from one bank to another.
    /// @param fromBankName The name of the Bank to move money away from.
    /// @param toBankName The name of the Bank to move the money to.
    /// @param value The value to be moved
    function transferMoney(string bankName, uint256 value, address to) external onlyBankAdministrator(bankName) {
        _transferMoney(bankName,value,to,msg.sender);
    }

    function receiveMoney(string bankName) external payable onlyIfActive {
        _processReceipt(bankByName[bankName],msg.value, msg.sender);
    }

    function issueReferendum(Proposal[] proposals) external onlyWithPermit("issueVote") {
        _issueReferendum(proposals);
    }

    /// @dev Make sure proposal is part of proposalsToBeImplemented
    function implementProposal(Proposal proposal) external onlyShardHolder {

    }

    function givePermit(string permitName) onlyIfActive {}

    function withdrawPermit(string permitName) onlyIfActive {}

    function hasPermit(address _holder, string permitName) view returns (bool) {
        switch (permitName) {
                    case "issueVote":
                        return _holder.permits.issueVote;
                    case "administrateIssueVotePermit":
                        return _holder.permits.administrateIssueVotePermit;
                    case "issueDividend":
                        return _holder.permits.issueDividend;
                    case "administrateIssueDividendPermit":
                        return _holder.permits.administrateIssueDividendPermit;
                    case "manageBank":
                        return _holder.permits.manageBank;
                    case "administrateManageBankPermit":
                        return _holder.permits.administrateManageBankPermit;
                    default:
                        revert();
                }
    }

    function hasVoted(address _shardHolder, Referendum referendum) view returns(bool){
        return referendum.hasVoted[shardByOwner[_shardholder]];
    }

    function bankExists(string bankName) returns(bool) {
        return bankByName[bankName].administrators.length >= 1;
    }

    function referendumExists(Referendum referendum) returns(bool) {
        return referendumIndex[referendum] > 0; // bigger than 0 because stored indices starts from 1
    }
    
    function dividendExists(Dividend dividend) view returns(bool) {
      return dividendIndex[dividend] > 0; ; // bigger than 0 because stored indices starts from 1
    }

    function isBankAdministrator(address _administrator, string bankName) view returns(bool) {
        return bankByName[bankName].isAdministrator[_administrator];
    }


    function getReferendumResult(Referendum referendum) pure returns(bool) {
        // if forFraction is bigger than 50%, then the vote is FOR
        if (referendum.forFraction.numerator / referendum.forFraction.denominator > 0.5) {
            return true;
        }
        return false;
    }

    function getBankIndex(Bank bank) view returns(uint256){
        return bankIndex[bank]-1; // -1 because stored indices starts from 1
    }

    function getReferendumIndex(Referendum referendum) view returns(uint256) {
        return referendumIndex[bank]-1; // -1 because stored indices starts from 1
    }

    /// @notice Dissolves and liquidizes the administerable entity. CAN'T BE UNDONE!!!
    function _dissolve() internal {
        active = false; // stops trading of Shards
        liquidization = new Dividend(address(this).balance, validShards); // sets up a final dividend for shardholders
    }


    function _moveMoney(string fromBankName, string toBankName, uint256 value, address by) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) onlyIfActive {
        Bank fromBank = bankByName[fromBankName];
        Bank toBank = bankByName[toBankName];
        require(value <= fromBankName.value, "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBank.value);
        bankFrom.value -= value;
        bankTo.value += value;
        emit MoneyMoved(fromBankName,toBankName,value,by);
    }

    function _transferMoney(string fromBankName, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) onlyIfActive {
        _processTransfer(fromBankName,value,to,by);
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
        emit MoneyTransfered(fromBankName,value,to,by);
    }

    function _processTransfer(string fromBankName, uint256 value, address to, address by) internal onlyExistingBank(fromBankName) {
        Bank fromBank = bankByName[fromBankName];
        require(value <= fromBank.value, "The value transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.value);
        fromBank.value -= value;
    }

    function _processReceipt(string toBankName, uint256 value, address from) internal onlyExistingBank(toBankName) {
        Bank toBank = bankByName[toBankName];
        toBank.value += value;
        emit MoneyReceived(toBank,value,from);
    }

    function _createBank(string bankName, address bankAdministrator) internal onlyIfActive {
        require(!bankExists(bankName), "Bank '"+bankName+"' already exists!");
        bankByName[bankName] = new Bank(0, [bankAdministrator]);
        bankIndex[bankByName[bankName]] = banks.length+1; // +1 because stored indices starts from 1
        banks.push(bankByName[bankName]);
        emit BankCreated({name:bankName, by:bankAdministrator});
    }

    function _deleteBank(string bankName) internal onlyIfActive {
        require(bankExists(bankName), "Bank '"+bankName+"' doesn't exists!");
        require(bankByName[bankName].value == 0, "Bank '"+bankName+"' must be empty before being deleted!");
        Bank bank = bankByName[bankName];
        banks[bankIndex[bank]] = banks[banks.length-1]; // -1 because stored indices starts from 1
        banks.pop();
        bankByName[bankName] = new Bank();
        emit BankDeleted({name:bankName});
    }

    function _issueReferendum(Proposal[] proposals, address by) internal onlyIfActive {
        Referendum referendum = new Referendum(proposals);
        pendingReferendumIndex[referendum] = pendingReferendums.length+1; // +1 to distinguish between empty values
        pendingReferendums.push(referendum);
        emit ReferendumIssued(referendum, by);
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

    function _implementProposal(Proposal proposal) internal onlyIfActive {
        /*
        for (uint i = 0; i < proposal.affected.length; i++) {
            proposal.affected[i].permits.
                switch (proposal.permitName) {
                    case "issueVote":
                        proposal.affected[i].permits.issueVote = proposal.newValue;
                        break;
                    case "administrateIssueVotePermit":
                        proposal.affected[i].permits.administrateIssueVotePermit = proposal.newValue;
                        break;
                    case "issueDividend":
                        proposal.affected[i].permits.issueDividend = proposal.newValue;
                        break;
                    case "administrateIssueDividendPermit":
                        proposal.affected[i].permits.administrateIssueDividendPermit = proposal.newValue;
                        break;
                    case "manageBank":
                        proposal.affected[i].permits.manageBank = proposal.newValue;
                        break;
                    case "administrateManageBankPermit":
                        proposal.affected[i].permits.administrateManageBankPermit = proposal.newValue;
                        break;
                    default:
                        revert();
                }
        }
        */
        this.call(bytes4(sha3(proposal.program)));
    }

}