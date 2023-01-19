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


    struct Bank {
        uint256 balance;
        address[] administrators;
        mapping(address => bool) isAdministrator;
    }

    /// @dev The structures from Permits all the way down to Referendum should be rethought and remade.

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
        address[] affected;
        string permitName;
        bool newValue;
    }

    struct Vote {
        Shard shard;
        bool for;
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

    // Bank by name
    Bank[] banks;
    mapping(string => Bank) bankByName;

    // mapping of addresses with permits
    mapping(address => Permits) permits;
    Referendum[] internal referendums;

    Dividend[] private dividends;

    // triggers when a referendum is issued
    event ReferendumIssued(
        Proposal[] proposals,
        address by
        );

    // triggers when a referendum is closed
    event ReferendumClosed(
        Referendum referendum,
        bool result
        )

    // triggers when a vote is cast
    event VoteCast(
        Referendum referendum,
        Shard shard,
        bool for
        );

    // triggers when money is received
    event MoneyReceived(
        address tokenAddress,
        Bank bank,
        uint256 value,
        address from
        );

    // triggers when money is transferred
    event MoneyTransfered(
        address tokenAddress,
        uint256 value,
        Bank bank,
        address to,
        address by
        );

    // triggers when bank is created
    event BankCreated(
        string name,
        address by
        )

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

    /// @notice Receives money and puts it into the 'main' bank when there's no supplying data 
    receive() payable {
        _receiveMoney(bankByName["main"],msg.value,msg.sender);
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param referendum The referendum to be voted on.
    /// @param for The boolean value signalling a for or against vote.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the right of the new shard to vote may unfairly perish, possibly making a referendum unsolvable.
    function vote(Referendum referendum, bool for) external onlyShardHolder hasNotVoted(referendum) {
        Shard memory _shard = shardByOwner[msg.sender];
        if (for) {
            referendum.forFraction = simplifyFraction(addFractions(referendum.forFraction,_shard.fraction));
        }
        else {
            referendum.againstFraction = simplifyFraction(addFractions(referendum.againstFraction,_shard.fraction));
        }
        referendum.hasVoted[_shard] = true;
        emit VoteCast(referendum, _shard, for)
    }

    /// @notice Issues a dividend to all current shareholders, which they'll have to claim themselves.
    /// @dev There is a potential problem when selling and or splitting a shard. Then the dividend right sometimes perishes.
    /// @param bankName The name of the bank to issue a dividend from.
    /// @param value The value of the dividend to be issued.
    function issueDividend(string bankName, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdministrator(bankName) {
        require(value <= bankByName[bankName].value, "Dividend value "+string(value)+" can't be more than bank value "+bank.value);
        bank.value -= value;
        Dividend newDividend = new Dividend(value,validShards);
        dividends.push(newDividend);
    }

    /// @notice Claims the value of an existing dividend corresponding to the shard holder's respective shard fraction.
    /// @param dividend The dividend to be claimed.
    /// @inheritdoc issueDividend
    function claimDividend(Dividend dividend) external onlyShardHolder {
        require(dividend.applicable[msg.sender] == true, "Not applicable for Dividend");
        dividendValue = shardByOwner[msg.sender].getDecimal() * dividend.value;
        dividend.applicable[msg.sender] = false;
        dividend.value -= dividendValue;
        (bool success, ) = address(msg.sender).call.value(dividendValue)("");
        require(success, "Transfer failed.");
    }

    function createBank(string bankName) external onlyWithPermit("manageBank") {
       _createBank(bankName, msg.sender);
    }

    function moveMoney(string fromBankName, string toBankName, uint256 value) external onlyBankAdministrator(fromBankName) {
        _moveMoney(fromBankName,bankTo,value);
    }

    function transferMoney(string bankName, uint256 value, address to) external onlyBankAdministrator(bankName) {
        _transferMoney(bankName,value,to);
    }

    function receiveMoney(string bankName, uint256 value) external payable {
        _receiveMoney(bankByName[bankName],value, msg.sender);z
    }

    function issueReferendum(string[] proposedChanges) external onlyWithPermit("issueVote") {}


    function givePermit(string permitName) {}

    function withdrawPermit(string permitName) {}

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

    function _moveMoney(string fromBankName, string toBankName, uint256 value) internal onlyExistingBank(fromBankName) onlyExistingBank(toBankName) {
        Bank fromBank = bankByName[fromBankName];
        Bank toBank = bankByName[toBankName];
        require(value <= fromBankName.value, "The value to be moved "+string(value)+" from '"+fromBankName+"' to '"+toBankName+"' can't be more than the value of '"+fromBankName+"':"+fromBank.value);
        bankFrom.value -= value;
        bankTo.value += value;
    }

    function _transferMoney(string fromBankName, uint256 value, address to) internal onlyExistingBank(fromBankName) {
        Bank fromBank = bankByName[fromBankName];
        require(value <= fromBank.value, "The value to be transferred "+string(value)+" from '"+fromBankName+"' can't be more than the value of that bank:"+fromBank.value);
        fromBank.value -= value;
        (bool success, ) = address(to).call.value(value)("");
        require(success, "Transfer failed.");
    }

    function _receiveMoney(string toBankName, uint256 value, address from) internal onlyExistingBank(toBankName) {
        Bank toBank = bankByName[toBankName];
        toBank.value += value;
        emit MoneyReceived(toBank,value,from);
    }

    function _createBank(string bankName, address bankAdministrator) internal {
        require(!bankExists(bankName), "Bank with name "+bankName+" already exists!");
        bankByName[bankName] = new Bank(0, [bankAdministrator]);
        banks.push(bankByName[bankName]);
        emit BankCreated({name:name, by:bankAdministrator});
    }

    function _implementProposal(Proposal proposal) internal {
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
    }
    /// @dev next step is to eliminate the for loops by implementing an incrementing counting mechanism and a Referendum mapping.
    function _closeReferendum(Referendum referendum) internal {
        bool memory result = getReferendumResult(referendum);
        emit ReferendumClosed(referendum, result);
        // if the vote turned out to be FOR
        if (result) {
            // implement the proposals of the referendum
            for (uint i = 0; i < referendum.proposals.length; i++) {
                _implementProposal(referendum.proposals[i]);
            }
        }
        // remove the referendum from the list
        for (uint i = 0; i < referendums.length; i++) {
            if (referendums[i] == referendum) {
                referendums[i] = referendums[referendums.length-1];
                referendums.pop();
                break;
            }
        }

    }

}