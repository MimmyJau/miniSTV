// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

uint256 constant MAX_DEPTH = 3;

struct Node {
    bytes32 id; // Key of current node.
    bytes32 parent; // Key of parent node.
    bytes32[] children; // Key of child nodes.
}

contract Tree {
    bytes32 private root;
    mapping(bytes32 => Node) private tree;

    constructor() {
        tree[root].id = root;
    }
    
    function generateId(bytes32 parent) private view returns (bytes32) {
        uint index = tree[parent].children.length;
        uint time = block.timestamp;
        return keccak256(abi.encode(parent, index, time));
    }

    function addChild(bytes32 parent) public returns (bytes32) {
        // Generate new key for child node.
        bytes32 newChild = generateId(parent);
        tree[parent].children.push(newChild);
        // Instantiate new child node.
        tree[newChild].parent = parent;
        tree[newChild].id = newChild;
        return newChild;
    }

    function getChildren(bytes32 parent) public view returns (bytes32[] memory) {
        return tree[parent].children;
    }

    function getParent(bytes32 node) public view returns (bytes32) {
        return tree[node].parent;
    }

    function getRoot() public view returns (bytes32) {
        return root;
    }

}

