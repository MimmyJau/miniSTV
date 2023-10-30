
pragma solidity ^0.8.13;

import { Tree } from "../src/Tree.sol";
import "forge-std/console.sol";

struct Node {
    uint256 proposal;
    uint256 votes;
    uint256 cumulativeVotes;
}

contract RankVote is Tree {
    bytes32 private root;
    mapping(bytes32 => Node) public tree;

    constructor() {
        // TODO: limit on how many rankings?
        root = super.getRoot();
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

    // Add Vote
    function addVote(uint256[] calldata vote) public {
        bytes32 parent = root;
        addVoteRecursive(parent, vote);
    }

    // Get Relevant Rankings
    function getRankingsWithProposals() public {}

    // function addRanking(uint256[] calldata ranking) private {
    //     bytes32 parent = root;
    //     for (uint i = 0; i < ranking.length; i++) {
    //         uint proposal = ranking[i];
    //         bytes32[] memory children = getChildren(parent);
    //         uint childIndex = findChild(parent, proposal);
    //         bytes32 child;
    //         if (childIndex == children.length) {
    //             child = addChild(parent, ranking[i]);
    //         } 
    //         parent = child;
    //     }
    // }

}
