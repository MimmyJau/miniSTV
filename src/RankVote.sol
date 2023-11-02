
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
        // TODO: limit on how many rankings?
        root = super.getRoot();
        numProposals = numProposals_;
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

    function eliminateProposal(uint proposal) public {
        eliminatedProposals[proposal] = true;
    }


    function tallyVotesRecursive(bytes32[] memory layer, uint[] memory tally) private returns (uint[] memory) {
        for (uint i = 0; i< layer.length; i++) {
            bytes32 ballot = layer[i];
            uint proposal = tree[ballot].proposal;
            if (eliminatedProposals[proposal]) {
                tally = tallyVotesRecursive(getChildren(ballot), tally);
            } else {
                tally[proposal] += tree[ballot].cumulativeVotes;
            }
        }
        return tally;
    }

    function tallyVotes() public returns (uint[] memory) {
        uint[] memory tally = new uint[](numProposals + 1); // Index 0 is not used in proposals.
        bytes32[] memory first = getChildren(root);
        return tallyVotesRecursive(first, tally);
    }
}
