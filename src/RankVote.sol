
pragma solidity ^0.8.13;

import { Tree } from "./Tree.sol";

import "./libraries/ArrayMaxMin.sol";

struct Node {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

contract RankVote is Tree {
    using ArrayMaxMin for uint256[];

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
    /// @param layer The current "layer" in the tree (i.e. the set of children that are being traversed)
    /// @param dProposal The proposal whose votes we would like to distribute
    /// @return An array with the updated vote count of each proposal after distribution
    function distributeVotesRecursive(
        uint[] memory dTally, 
        bytes32[] memory layer, 
        uint dProposal 
    ) private returns (uint[] memory){

        for (uint i = 0; i < layer.length; i++) {
            bytes32 node32 = layer[i];
            uint256 proposal = tree[node32].proposal;

            // if the node is eliminated, continue traversing its children
            if (eliminatedProposals[proposal]) {
                dTally = distributeVotesRecursive(dTally, getChildren(layer[i]), dProposal);
            }

            // if this node's votes ought to be distributed, tally all relevant descendents
            if (dProposal == proposal) {
                dTally = tallyDescendents(dTally, layer[i]);
            }
        }

        return dTally;
    }


    /// @notice Entrypoint for distributing votes (after proposal has won or been eliminated)
    /// @dev Calls distributeVotesRecursive to traverse tree and count votes
    /// @param tally Array of current vote counts for each proposal
    /// @param dProposal The proposal whose votes we would like to distribute
    /// @param excessVotes Number of excess votes to be distribuetd
    /// @return An array with the vote count of each proposal after distribution
    function distributeVotes(
        uint256[] memory tally, 
        uint256 dProposal,
        uint256 excessVotes
    ) public returns (uint[] memory) {

        // index 0 is not used in proposals
        uint256[] memory dTally = new uint256[](numProposals + 1);
        bytes32[] memory first = getChildren(root);

        // aggregate all the votes to be distributed
        dTally = distributeVotesRecursive(dTally, first, dProposal);

        // allocate the excess votes
        uint256 total = sumArray(dTally);
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
