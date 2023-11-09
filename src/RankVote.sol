
pragma solidity ^0.8.13;

import { Tree } from "./Tree.sol";

import "./libraries/ArrayMaxMin.sol";
import "./libraries/ArrayUtils.sol";

struct Node {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

contract RankVote is Tree {
    using ArrayMaxMin for uint256[];
    using ArrayUtils for uint256[];

    bytes32 private root;
    uint256 private numProposals;
    mapping(bytes32 => Node) public tree;
    mapping(uint256 => bool) private eliminatedProposals; 

    constructor(uint numProposals_) {
        root = super.getRoot();
        numProposals = numProposals_;
    }

    ////////////////////////////////////////////////////////////////////////
    // Rank Votes - Helper Functions

    function totalVotes() public view returns (uint) {
        return tree[root].cumulativeVotes;
    }

    function eliminateProposal(uint proposal) public {
        eliminatedProposals[proposal] = true;
    }

    function getEliminatedProposals() private view returns (bool[] memory) {
        bool[] memory eliminatedProposals_ = new bool[](numProposals + 1);
        for (uint i = 1; i <= numProposals; i++) {
            eliminatedProposals_[i] = eliminatedProposals[i];
        }
        return eliminatedProposals_;
    }

    /// @dev Returns a list of proposals that are still active. We need 
    ///      to pass in as a param to maxSubset() when counting votes.
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
    // Rank Votes - Core Functions

    // Check if a proposal is already a child of another Node.
    function findChild(bytes32 parent, uint256 proposal) private view returns (uint256) {
        bytes32[] memory children = getChildren(parent);
        uint i;
        for (i = 0; i < children.length; i++) {
            if (tree[children[i]].proposal == proposal) {
                return i;
            }
        }
        return i;
    }

    function addChild(bytes32 parent, uint256 proposal) private returns (bytes32) {
        bytes32 child = super.addChild(parent);
        tree[child].proposal = proposal;
        return child;
    }

    function updateCumulativeVotes(bytes32 node) private {
        bytes32[] memory children = getChildren(node);
        tree[node].cumulativeVotes = 0;
        for (uint i = 0; i < children.length; i++) {
            bytes32 child = children[i];
            tree[node].cumulativeVotes += tree[child].cumulativeVotes;
        }
        tree[node].cumulativeVotes += tree[node].votes;
    }

    function addVoteRecursive(bytes32 parent, uint256[] calldata proposals) private {
        uint proposal = proposals[0];
        bytes32[] memory children = getChildren(parent);
        uint childIndex = findChild(parent, proposal);
        bytes32 child;

        // If child does not exist, create it.
        if (childIndex == children.length) {
            child = addChild(parent, proposals[0]);
        } else {
            child = children[childIndex];
        }

        // If this is the last proposal in the ranking, add a vote to the child.
        if (proposals.length == 1) {
            tree[child].votes += 1;
            updateCumulativeVotes(child);
        } else {
            addVoteRecursive(child, proposals[1:]);
        }
        updateCumulativeVotes(parent);
    }

    function addVote(uint256[] calldata vote) public {
        require(vote.unique());
        bytes32 parent = root;
        addVoteRecursive(parent, vote);
    }

    ////////////////////////////////////////////////////////////////////////
    // STV - Core Functions

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
        if (children.length == 0) return dTally;

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


    /// @dev Core function for traverseing tree and counting votes
    /// @param layer The current "layer" of children that is being traversed
    /// @param tally The running count of votes for each proposal
    /// @return tally The updated tally
    function tallyVotesRecursive(
        bytes32[] memory layer, 
        uint[] memory tally 
    ) private returns (uint[] memory) {

        for (uint i = 0; i< layer.length; i++) {
            bytes32 node32 = layer[i];
            uint proposal = tree[node32].proposal;

            // if proposal stil valid, then add votes
            if (!eliminatedProposals[proposal]) {
                tally[proposal] += tree[node32].cumulativeVotes;
            } else {
                tally = tallyVotesRecursive(getChildren(node32), tally);
            }
        }

        return tally;
    }

    /// @notice Entrypoint for tallying votes
    /// @dev Calls tallyVotesRecursive to traverse tree and count votes
    /// @return An array with the vote count of each proposal
    function tallyVotes() public returns (uint[] memory) {
        // index 0 is not used in proposals
        uint[] memory tally = new uint[](numProposals + 1); 

        bytes32[] memory first = getChildren(root);

        return tallyVotesRecursive(first, tally);
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
        if (lastTally.length == 0) return tiedProposals[0];

        // 1) who had the least 1st-rank votes
        uint256[] memory losers = firstTally.minSubset(tiedProposals);
        if (losers.length == 1) {
            return losers[0];
        }

        // 2) who had least votes in last tally
        losers = lastTally.minSubset(tiedProposals);
        if (losers.length == 1) {
            loser = losers[0];
        } 

        // 3) "random" TODO: implement actual RNG
        loser = losers[0];

        return loser;
    }

    /// @notice Determine winners of the STV vote
    /// @dev The function doesn't guarantee that the number of winners 
    ///      (i.e. propoosals whose vote counts will surpass the quota) 
    ///      will be equal to argument `numWinners` passed in as a param. 
    ///      This is more likely to occur if there are a lot of proposals 
    ///      and very few votes. 
    /// @param numWinners The ideal number of winners; algorithm will 
    ///        attempt to generate this number winners
    /// @return winners A list of winners
    function finalize(uint256 numWinners) internal returns (uint256[] memory winners) {

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
            if (count > quota) {
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
                uint256[] memory minIndices = tally.minTally();
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
