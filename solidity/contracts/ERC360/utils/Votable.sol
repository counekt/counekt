pragma solidity ^0.8.20;


abstract contract Votable {

    enum ReferendumStatus {
        inactive,
        pending,
        passed
    }

    /// @notice Struct representing info of a Referendum.
    /// @param issuer The issuer of the Referendum.
    /// @param proposalFuncs Names of functions to be called during implementation.
    /// @param proposalArgs The encoded parameters passed to the function calls as part of the implementation of the proposals.
    struct ReferendumInfo {
        address issuer;
        string[] proposalFuncs;
        bytes[] proposalArgs;
    }

    /// @notice Votes on a existing referendum, with a fraction corresponding to the shard of the holder.
    /// @param shard The Shard to vote with.
    /// @param referendum The referendum to be voted on.
    /// @param favor The boolean value signalling a FOR or AGAINST vote.
    function vote(bytes32 shard, uint256 referendum, bool favor) external virtual {
        require(statusByReferendum[referendum] == ReferendumStatus.pending, "RNP");
        require(!hasActionCompleted[referendum][shard]);
        require(shardExisted(shard,referendum), "SNV");
        hasActionCompleted[referendum][shard] = true;
        if (favor) {
            favorAmountByReferendum[referendum] += infoByShard[shard].amount;
        }
        totalAmountByReferendum[referendum] += infoByShard[shard].amount;
        
        emit VoteCast(referendum, favor, msg.sender);
        if ((favorAmountByReferendum[referendum] / totalShardAmountByClock[referendum]) * 2 > 1) {
            statusByReferendum[referendum] = ReferendumStatus.passed;
            emit ReferendumClosed(referendum,true);

        }
        else if (((totalAmountByReferendum[referendum] - favorAmountByReferendum[referendum]) / totalShardAmountByClock[referendum]) * 2 > 1) {

            statusByReferendum[referendum] = ReferendumStatus.inactive;
            emit ReferendumClosed(referendum,false);
        }
    }

}