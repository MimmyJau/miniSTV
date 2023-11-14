
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

    bytes32 internal root;
    mapping(bytes32 => Node) internal tree; 

    constructor() {
        root = super.getRoot();
    }

    /// @dev Returns total votes
    function totalVotes() internal view returns (uint) {
        return tree[root].cumulativeVotes;
    }

    /// @dev Checks if a parent node has a proposal as a child, if the parent does NOT have
    /// the proposal as a child, the function returns the length of the array.
    /// @param parent The parent node
    /// @param proposal The proposal
    /// @return index The index of the matched child node OR 
    ///         the length of the array if the child does not exist.
    function findChild(bytes32 parent, uint256 proposal) private view returns (uint256 index) {
        bytes32[] memory children = getChildren(parent);
        uint i;
        for (i = 0; i < children.length; i++) {
            if (tree[children[i]].proposal == proposal) {
                return i;
            }
        }
        return i;
    }

    /// @dev Adds a follow-on proposal to an existing parent node. For example if we have a tree
    /// that looks like [1, 2, 3] and we add 4 to the node 2, then we'll have two branches out 
    /// of node 2 ([1, 2, 3] and [1, 2, 4] where [1, 2] are the same nodes in both branches).
    /// @param parent The parent node or vote
    /// @param proposal The proposal to add as a child to the parent node
    /// @return child32 The address of the new child node
    function addChild(bytes32 parent, uint256 proposal) private returns (bytes32 child32) {
        child32 = super.addChild(parent);
        tree[child32].proposal = proposal;
        return child32;
    }

    /// @dev Each vote node contains a cumulative vote count that is the sum of all votes
    /// of its child nodes up to and including its own votes. This function updates this 
    /// value for a single node (i.e. does not recursively update the value in all nodes).
    /// @param node The node whose cumulativeVotes count is being updated
    function updateCumulativeVotes(bytes32 node) private {
        bytes32[] memory children = getChildren(node);
        tree[node].cumulativeVotes = 0;
        for (uint i = 0; i < children.length; i++) {
            bytes32 child = children[i];
            tree[node].cumulativeVotes += tree[child].cumulativeVotes;
        }
        tree[node].cumulativeVotes += tree[node].votes;
    }

    /// @dev This function does most of the heavy-lifting for adding a vote to the tree.
    /// It will traverse the tree and add as many nodes as necessary for the ranking 
    /// (or add no nodes if the ranking already exists in the tree). It will then update
    /// all the cumnulativeVotes counts in a bottoms-up fashion.
    /// @param parent The current node / vote
    /// @param vote The remaining rankings of the vote
    function addVoteRecursive(bytes32 parent, uint256[] calldata vote) private {
        uint proposal = vote[0];
        bytes32[] memory children = getChildren(parent);
        uint256 childIndex = findChild(parent, proposal);
        bytes32 child;

        // if child does not exist, create it (findChild returns length of array if child doesn't exist)
        if (childIndex == children.length) {
            child = addChild(parent, vote[0]);
        } else {
            child = children[childIndex];
        }

        // if this is the last proposal in the ranking, add a vote to the child
        if (vote.length == 1) {
            tree[child].votes += 1;
            updateCumulativeVotes(child);
        } else {
            addVoteRecursive(child, vote[1:]);
        }
        updateCumulativeVotes(parent);
    }

    /// @notice Add a ranked vote
    /// @dev The entrypoint for adding a vote to the tree. Hands off to addVoteRecursive
    /// to do most of the heavy-lifting.
    /// @param vote The user's vote ranking.
    function addVote(uint256[] calldata vote) public {
        require(vote.unique());
        bytes32 parent = root;
        addVoteRecursive(parent, vote);
    }
}
