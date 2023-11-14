// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

uint256 constant MAX_DEPTH = 3;

struct Node {
    bytes32 id; // Key of current node.
    bytes32 parent; // Key of parent node.
    bytes32[] children; // Keys of child nodes.
}

contract Tree {
    bytes32 private root;
    mapping(bytes32 => Node) private tree;

    constructor() {
        tree[root].id = root;
    }
    
    /// @dev Generates a new and unique key (or address) for a child node
    function generateId(bytes32 parent) private view returns (bytes32) {
        uint index = tree[parent].children.length;
        uint time = block.timestamp;
        return keccak256(abi.encode(parent, index, time));
    }

    /// @dev Adds a child node to the parent node
    function addChild(bytes32 parent) internal returns (bytes32) {

        // generate new key for child node
        bytes32 newChild = generateId(parent);
        tree[parent].children.push(newChild);

        // instantiate new child node
        tree[newChild].parent = parent;
        tree[newChild].id = newChild;

        return newChild;
    }

    /// @dev Returns an array of keys of the child nodes
    function getChildren(bytes32 parent) internal view returns (bytes32[] memory) {
        return tree[parent].children;
    }

    /// @dev Returns the key of the parent node
    function getParent(bytes32 node) internal view returns (bytes32) {
        return tree[node].parent;
    }

    /// @dev Returns the key of the root node of the tree
    function getRoot() internal view returns (bytes32) {
        return root;
    }

}

