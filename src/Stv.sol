
pragma solidity ^0.8.13;

import { RankVote } from "./RankVote.sol";

import "./libraries/ArrayMaxMin.sol";
import "./libraries/ArrayUtils.sol";

contract Stv is RankVote {
    using ArrayMaxMin for uint256[];
    using ArrayUtils for uint256[];

    mapping(uint256 => bool) internal eliminatedProposals; 
    uint256 public numProposals;
    uint256 public numWinners;

    constructor(uint256 numProposals_, uint256 numWinners_) RankVote() {
        numProposals = numProposals_;
        numWinners = numWinners_;
    }

    ////////////////////////////////////////////////////////////////////////
    // Helper Functions

    /// @dev Eliminates proposals from future tallies
    /// @param proposal The proposal to be eliminated
    function eliminateProposal(uint256 proposal) public {
        eliminatedProposals[proposal] = true;
    }

    /// @dev Returns a list of proposals that are still active. We need 
    ///      to pass this in as a param to maxSubset() when counting votes.
    /// @return activeProposals A list of proposals that haven't been eliminated
    function getActiveProposals() internal view returns (uint256[] memory activeProposals) {
        uint256 countActiveProposals = 0;

        // count how many active proposals there are
        for (uint256 i = 1; i <= numProposals; i++) {
            if (!eliminatedProposals[i]) {
                countActiveProposals++;
            }
        }

        activeProposals = new uint256[](countActiveProposals);
        uint256 j = 0;

        // assign active proposals to memory array
        for (uint256 i = 1; i <= numProposals; i++) {
            if (!eliminatedProposals[i]) {
                activeProposals[j++] = i;
            }
        }

        return activeProposals;
    }

    ////////////////////////////////////////////////////////////////////////
    // Core Functions

    /// @notice Calculates the droop quota, the minimum votes required for a proposal to "win"
    /// @return The droop quota as an integer
    function droopQuota() public view returns (uint256) {
        return totalVotes() / (numProposals + 1) + 1;
    }

    /// @dev This function distributes a node's votes to all of its descendents
    /// @param dTally The running count of the votes and proposals that are being distributed
    /// @param node The node whose votes we want to distribute to descendents 
    /// @return An updated dTally that includes node's descendents
    function tallyDescendents(
        uint[] memory dTally, 
        bytes32 node 
    ) private view returns (uint[] memory) {

        // base case is we reach leaf node and have already aggregated its votes
        bytes32[] memory children = getChildren(node);

        // if not a leaf node, aggregate votes of its child nodes
        for (uint i = 0; i < children.length; i++) {
            bytes32 node32 = children[i];
            uint256 proposal = tree[node32].proposal;
            uint256 votes = tree[node32].cumulativeVotes;

            // if proposal is valid, aggregate votes, otherwise traverse its descendents
            if (!eliminatedProposals[proposal]) {
                dTally[proposal] += votes;
            } else {
                dTally = tallyDescendents(dTally, children[i]);
            }
        }
        
        return dTally;
    }

    /// @dev This function traverses tree to find nodes that correspond to dProposal, but it doesn't tally (that's left for tallyDescendents)
    /// @param dTally The running count of the votes and proposals that dProposal will be distribuetd to
    /// @param node The current node being traversed
    /// @param dProposal The proposal whose votes we would like to distribute
    /// @return An array with the updated vote count of each proposal after distribution
    function distributeVotesRecursive(
        uint[] memory dTally, 
        bytes32 node,
        uint dProposal 
    ) private returns (uint[] memory){

        uint256 proposal = tree[node].proposal;
        
        if (proposal == dProposal) {
            dTally = tallyDescendents(dTally, node);
        } 

        // if the node is eliminated, continue traversing its children
        else if (eliminatedProposals[proposal] || proposal == 0) {
            bytes32[] memory children = getChildren(node);

            for (uint256 i = 0; i < children.length; i++) {
                dTally = distributeVotesRecursive(dTally, children[i], dProposal);
            }

        } 

        return dTally;
    }

    /// @notice Entrypoint for distributing votes (after proposal has won or been eliminated)
    /// @dev Calls distributeVotesRecursive to traverse tree and count votes
    /// @param tally Array of current vote counts for each proposal
    /// @param dProposal The proposal whose votes we would like to distribute
    /// @param excessVotes Number of excess votes to be distributed
    /// @return An array with the vote count of each proposal after distribution
    function distributeVotes(
        uint256[] memory tally, 
        uint256 dProposal,
        uint256 excessVotes
    ) public returns (uint[] memory) {

        // index 0 is not used in proposals
        uint256[] memory dTally = new uint256[](numProposals + 1);

        // aggregate all the votes to be distributed
        dTally = distributeVotesRecursive(dTally, root, dProposal);

        // allocate the excess votes
        uint256 total = dTally.sum();
        if (total == 0)  return tally;

        for (uint256 i = 1; i <= numProposals; i++) {
            tally[i] += dTally[i] * excessVotes / total;
        }

        return tally;
    }

    /// @notice Entrypoint for tallying votes
    /// @dev Calls tallyDescendents to traverse tree and count votes
    /// @return tally An array with the vote count of each proposal
    function tallyVotes() public view returns (uint[] memory tally) {
        // index 0 is not used in proposals
        tally = new uint256[](numProposals + 1);

        // aggregate all the votes to be distributed
        tally = tallyDescendents(tally, root);

        return tally;
    }

    
    /// @dev Tiebreaker when >1 proposal surpasses quota
    /// @param firstTally The intiial tally. Shows who has the most first-rank votes.
    /// @param lastTally The previous tally
    /// @param tiedProposals Array of tied proposals
    /// @return winner The proposoal that "won" the tiebreak
    function tiebreakWinner(
        uint256[] memory firstTally, 
        uint256[] memory lastTally, 
        uint256[] memory tiedProposals
    ) internal pure returns (uint256 winner) {
        if (lastTally.length == 0) return tiedProposals[0];

        // 1) who had the most 1st-rank votes
        uint256[] memory winners = firstTally.maxSubset(tiedProposals);
        if (winners.length == 1) {
            return winners[0];
        }

        // 2) who had most votes in last tally
        winners = lastTally.maxSubset(tiedProposals);
        if (winners.length == 1) {
            return winner = winners[0];
        } 


        // 3) "random" TODO: implement actual RNG
        winner = winners[0];

        return winner;
    }

    /// @notice WIP! This is a yet-to-be-implemented RNG for picking proposal to eliminate.
    /// @dev As of now, it picks the last element in the list, biasing towards earlier proposals
    /// @param proposals List of proposals from which you'd like to pick a random one
    /// @return randomLoser The randomly-selected proposal to be eliminated
    function randomLoser(uint256[] memory proposals) private pure returns (uint256 randomLoser) {
        return proposals[proposals.length - 1];
    }

    /// @dev Tiebreaker when >1 proposal are eligible to be eliminated 
    /// @param firstTally The intiial tally. Shows who has the least first-rank votes.
    /// @param lastTally The previous tally
    /// @param tiedProposals Array of tied proposals
    /// @return loser The proposal that "lost" the tiebreak
    function tiebreakLoser(
        uint256[] memory firstTally, 
        uint256[] memory lastTally, 
        uint256[] memory tiedProposals
    ) internal pure returns (uint256 loser) {
        if (lastTally.length == 0) return randomLoser(tiedProposals);

        // 1) who had the least 1st-rank votes
        uint256[] memory losers = firstTally.minSubset(tiedProposals);
        if (losers.length == 1) {
            return losers[0];
        }

        // 2) who had least votes in last tally
        losers = lastTally.minSubset(tiedProposals);
        if (losers.length == 1) {
            return losers[0];
        } 

        return randomLoser(losers);
    }

    /// @notice Determine winners of the STV vote
    /// @dev The function doesn't guarantee that the number of winners 
    ///      (i.e. propoosals whose vote counts will surpass the quota) 
    ///      will be equal to argument `numWinners` passed in as a param. 
    ///      This is more likely to occur if there are a lot of proposals 
    ///      and very few votes. 
    /// @return winners A list of winners
    function finalize() public returns (uint256[] memory winners) {

        winners = new uint256[](numWinners);
        uint256 numWinners_ = 0;
        uint256 quota = droopQuota();

        // when a proposal exceeds the quota or is eliminated, decrement this number 
        uint256 activeProposals = numProposals;

        // count votes
        uint256[] memory tally = tallyVotes();
        uint256[] memory firstTally = tally.copy();
        uint256[] memory lastTally;

        while (numWinners_ < numWinners && activeProposals > 0) {
            // find max element
            uint256[] memory maxIndices = tally.maxSubset(getActiveProposals());

            // pick one of the propoosals and get their vote count
            uint256 proposal = maxIndices[0];
            uint256 count = tally[proposal];
            uint256 excessVotes;

            // if votes count crosses threshold, we'll pick a winner
            if (count >= quota) {
                // if there's a tie, break tie
                if (maxIndices.length > 1) {
                    proposal = tiebreakWinner(firstTally, lastTally, maxIndices);

                } 

                winners[numWinners_++] = proposal;
                eliminateProposal(proposal);
                excessVotes = count - quota;
            } 

            // if vote count doesn't cross threshold, eliminate
            else {
                uint256[] memory minIndices = tally.minSubset(getActiveProposals());
                proposal = minIndices[0];

                if (minIndices.length > 1) {
                    proposal = tiebreakLoser(firstTally, lastTally, minIndices);
                } 

                eliminateProposal(proposal);
                excessVotes = tally[proposal];
            }

            activeProposals--;

            // distribute votes 
            if (numWinners_ < numWinners) {
                lastTally = tally.copy();
                tally = distributeVotes(tally, proposal, excessVotes);
            }
        }

        if (numWinners_ != numWinners) {
            uint256[] memory winners_ = new uint256[](numWinners_);
            for (uint256 i = 0; i < numWinners_; i++) {
                winners_[i] = winners[i];
            }

            winners = winners_;
        }

        return winners;

    }
}
