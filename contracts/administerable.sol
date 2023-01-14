pragma solidity ^0.8.4;

import "../shardable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/utils/ERC20Holder.sol";

/// @title A fractional DAO-like non-fungible token that can be administered by its shareholders
/// @author Frederik W. L. Christoffersen
/// @notice This contract is used as an administerable business entity. Be aware that a sell transfers a service fee of 2.5% to Counekt.
/// @dev All function calls are currently implemented without side effects
/// @custom:commercial This is a commercial contract.
contract Administerable is Shardable, ERC20Holder {
    
    constructor() public {

    }

    struct Bank {
        uint256 balance;
        address[] administrators;
    }

    // Bank by name
    mapping(string => Bank) public banks;


    struct Permits {
        // Issue Vote
        bool issueVote;
        bool administrateIssueVotePermit; // Permission to distribute and withdraw the permission to issue a vote

        // Issue Dividend
        bool issueDividend;
        bool administrateIssueDividendPermit; // Permission to distribute and withdraw the permission to issue a dividend

        // Manage Bank
        bool manageBank;
        bool administrateManageBankPermit; // Permission to distribute and withdraw the permission to manage a bank

        // 

    }

    // mapping of addresses with permits

    mapping(address => Permits) permits;


    // modifier to make sure msg.sender has permit
    modifier onlyWithPermit(string permitName) {
        require(hasPermit(msg.sender, permitName));
    }

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

    Referendum[] internal referendums;


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

    function hasVoted(address _shardHolder, Referendum referendum) {
        for (uint i = 0; i < referendum.votes.length; i++) {
            if (_shardHolder.ownerOf(referendum.votes[i].shard)) {
                return true;
            }
        }

        return false;
    }

    modifier hasNotVoted(Referendum referendum) {
        require(!hasVoted(msg.sender,referendum));
    }

    function vote(Referendum referendum, bool for) external onlyShardHolder hasNotVoted(referendum) {
        Shard memory _shard = getShardByHolder(msg.sender);
        referendums[referendum].votes.push(new Vote(_shard, for));
        emit VoteCast(referendum, _shard, for)
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

    fallback() payable {}

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

    function issueDividend(Bank bank, uint256 value) external onlyWithPermission("issueDividend") {}

    function issueReferendum(string[] proposedChanges) external onlyWithPermission("issueVote") {}

    function createBank(string name) external onlyWithPermission("manageBank") {
        require(banks[name] == Bank)
        banks[name] = new Bank(0, [msg.sender])
    }

    function givePermission(string permissionName) {}

    function withdrawPermission(string permissionName) {}

}