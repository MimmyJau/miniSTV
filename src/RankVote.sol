
pragma solidity ^0.8.13;

import { Tree } from "../src/Tree.sol";

struct Node {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

contract RankVote is Tree {
    bytes32 private root;
    uint private numProposals;
    mapping(bytes32 => Node) public tree;
    mapping(uint256 => bool) private eliminatedProposals; 

    constructor(uint numProposals_) {
        root = super.getRoot();
        numProposals = numProposals_;
    }

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
        bytes32 parent = root;
        require(eachElementUnique(vote));
        addVoteRecursive(parent, vote);
    }

    ////////////////////////////////////////////////////////////////////////
    // Helper Functions

    function eachElementUnique(uint256[] calldata ranking) private pure returns (bool) {
        for (uint i = 0; i < ranking.length - 1; i++) {
            uint proposal = ranking[i];
            for (uint j = i + 1; j < ranking.length; j++) {
                if (proposal == ranking[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function sumArray(uint[] memory arr) private pure returns (uint) {
        uint total = 0;
        for (uint i = 0; i < arr.length; i++) {
            total += arr[i];
        }
        return total;
    }

    ////////////////////////////////////////////////////////////////////////
    // STV - Core Functions

    function droopQuota() public view returns (uint) {
        return totalVotes() / (numProposals + 1) + 1;
    }

    function tallyDescendents(
        uint[] memory dTally, 
        bytes32 node, 
        bool[] memory eliminatedProposals_
    ) private view returns (uint[] memory) {
        bytes32[] memory children = getChildren(node);
        if (children.length == 0) {
            return dTally;
        }
        for (uint i = 0; i < children.length; i++) {
            Node memory child = tree[children[i]];
            if (eliminatedProposals_[child.proposal]) {
                dTally = tallyDescendents(dTally, children[i], eliminatedProposals_);
            } else {
                dTally[child.proposal] += child.cumulativeVotes;
            }
        }
        return dTally;
    }

    function distributeVotesRecursive(
        uint[] memory dTally, 
        bytes32[] memory layer, 
        uint dProposal, 
        bool[] memory eliminatedProposals_
    ) private returns (uint[] memory){
        for (uint i = 0; i < layer.length; i++) {
            Node memory node = tree[layer[i]];
            if (eliminatedProposals_[node.proposal]) {
                dTally = distributeVotesRecursive(dTally, getChildren(layer[i]), dProposal, eliminatedProposals_);
            }
            if (dProposal == node.proposal) {
                dTally = tallyDescendents(dTally, layer[i], eliminatedProposals_);
            }
        }
        return dTally;
    }

    function distributeVotes(uint[] memory tally, uint dProposal) public returns (uint[] memory) {
        // Gather all the votes to be distributed.
        uint[] memory dTally = new uint[](numProposals + 1);
        bytes32[] memory ballots = getChildren(root);
        bool[] memory eliminatedProposals_ = getEliminatedProposals();
        dTally = distributeVotesRecursive(dTally, ballots, dProposal, eliminatedProposals_);

        // Allocate the excess votes based.
        uint excessVotes = tally[dProposal] - droopQuota();
        uint total = sumArray(dTally);
        for (uint i = 1; i <= numProposals; i++) {
            tally[i] += dTally[i] * excessVotes / total;
        }
        return tally;
    }


    /// @dev Core function for traverseing tree and counting votes
    /// @param layer The current "layer" of children that is being traversed
    /// @param tally The running count of votes for each proposal
    /// @return tally The updated tally
    function tallyVotesRecursive(bytes32[] memory layer, uint[] memory tally, bool[] memory eliminatedProposals_) private returns (uint[] memory) {
        for (uint i = 0; i< layer.length; i++) {
            bytes32 ballot = layer[i];
            uint proposal = tree[ballot].proposal;
            if (eliminatedProposals_[proposal]) {
                tally = tallyVotesRecursive(getChildren(ballot), tally, eliminatedProposals_);
            } else {
                tally[proposal] += tree[ballot].cumulativeVotes;
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
        bool[] memory eliminatedProposals_ = getEliminatedProposals();

        return tallyVotesRecursive(first, tally, eliminatedProposals_);

    }

    function tallyStv() public returns (uint[] memory) {
        // tally
        // find max element
            // if it crosses threshold, pick winner
                // if there are more than one, pick higher one
                // if there's a tie, break tie
            // if it doesn't cross threshold, eliminate
                // if there's a tie, break tie
        // distribute votes 
    }
}
