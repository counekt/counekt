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

    }


    struct Bank {
        uint256 balance;
        mapping(address => bool) administrators;
    }

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
        Vote[] votes;
    }

    struct Dividend {
        uint256 value;
        mapping(Shard => bool) applicable;
    }

    // Bank by name
    mapping(string => Bank) public banks;

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
        uint256 value,
        address from,
        Bank bank
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

    // modifier to make sure msg.sender has permit
    modifier onlyWithPermit(string permitName) {
        require(hasPermit(msg.sender, permitName));
    }

    // modifier to make sure msg.sender has NOT voted on a referendum
    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    // modifier to make sure msg.sender is administrator of a bank
    modifier onlyBankAdministrator(Bank bank) {
        require(isBankAdministrator(msg.sender, bank));
    }

    receive() payable {}

    fallback() payable {}


    function vote(Referendum referendum, bool for) external onlyShardHolder hasNotVoted(referendum) {
        Shard memory _shard = getShardByHolder(msg.sender);
        referendums[referendum].votes.push(new Vote(_shard, for));
        emit VoteCast(referendum, _shard, for)
    }

    function issueDividend(Bank bank, uint256 value) external onlyWithPermit("issueDividend") onlyBankAdministrator(bank) {
        require(value <= bank.value, "Dividend value "+string(value)+" can't be more than bank value "+bank.value);

    }

    function issueReferendum(string[] proposedChanges) external onlyWithPermit("issueVote") {}

    function createBank(string name) external onlyWithPermit("manageBank") {
        require(banks[name].administrators.length > 0, "Bank with name "+name+" already exists!");
        banks[name] = new Bank(0, [msg.sender]);
        emit BankCreated({name:name, by:msg.sender});
    }

    function givePermission(string permissionName) {}

    function withdrawPermission(string permissionName) {}

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
        for (uint i = 0; i < referendum.votes.length; i++) {
            if (_shardHolder.ownerOf(referendum.votes[i].shard)) {
                return true;
            }
        }

        return false;
    }

    function isBankAdministrator(address _administrator, Bank bank) view returns(bool) {
        return bank.administrators[msg.sender];
    }

    function getForFraction(Referendum referendum) pure returns(Fraction) {
        Fraction forFraction = Fraction(0,1);

        // the shard fractions of all the for-votes are counted together
        for (uint i = 0; i < referendum.votes.length; i++) {
        
            if (referendum.votes[i].for) {
                forFraction = addFractions(forFraction,referendum.votes[i].shard.fraction);
            }

        }
        return forFraction;
    }

    function getReferendumResult(Referendum referendum) pure returns(bool) {
        Fraction forFraction = getForFraction(referendum);
        // if forFraction is bigger than 50%, then the vote is FOR
        if (forFraction.numerator / forFraction.denominator > 0.5) {
            return true;
        }
        return false;
    }

    function _implementProposal(Proposal proposal) internal private {
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