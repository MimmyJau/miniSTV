// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Tree, Node} from "../src/Tree.sol";

contract TreeHarness is Tree {
    constructor() Tree() {}

    function exposed_addChild(bytes32 parent) external returns (bytes32) {
        return addChild(parent);
    }

    function exposed_getChildren(bytes32 parent) external view returns (bytes32[] memory) {
        return getChildren(parent);
    }

    function exposed_getParent(bytes32 node) external view returns (bytes32) {
        return getParent(node);
    }

    function exposed_getRoot() external view returns (bytes32) {
        return getRoot();
    }
}

contract TreeTest is Test {
    TreeHarness public tree;

    function setUp() public {
        tree = new TreeHarness();
    }

    function test_Root() public {
        bytes32 root = tree.exposed_getRoot();
        assertEq(root, bytes32(0));
        // console2.logBytes32(root);
    }

    function test_OneChild() public {
        bytes32 root = tree.exposed_getRoot();
        bytes32 child = tree.exposed_addChild(root);
        bytes32[] memory rootChildren = tree.exposed_getChildren(root);
        bytes32 childParent = tree.exposed_getParent(child);
        assertEq(child, rootChildren[0]);
        assertEq(childParent, root);
        assertNotEq(root, child);
        // console2.logBytes32(root);
        // console2.logBytes32(child);
    }

    function test_TwoChildren() public {
        bytes32 root = tree.exposed_getRoot();
        bytes32 child = tree.exposed_addChild(root);
        bytes32 child2 = tree.exposed_addChild(root);
        bytes32[] memory rootChildren = tree.exposed_getChildren(root);
        bytes32 childParent = tree.exposed_getParent(child);
        bytes32 child2Parent = tree.exposed_getParent(child2);
        assertEq(child, rootChildren[0]);
        assertEq(childParent, root);
        assertEq(child2, rootChildren[1]);
        assertEq(child2Parent, root);
        assertNotEq(child, child2);
        // console2.logBytes32(root);
        // console2.logBytes32(child);
        // console2.logBytes32(child2);
    }

    function test_GrandChild() public {
        bytes32 root = tree.exposed_getRoot();
        bytes32 child = tree.exposed_addChild(root);
        bytes32 grandchild = tree.exposed_addChild(child);
        bytes32[] memory children = tree.exposed_getChildren(root);
        bytes32[] memory grandchildren = tree.exposed_getChildren(children[0]);
        bytes32 grandchildParent = tree.exposed_getParent(grandchildren[0]);
        bytes32 childParent = tree.exposed_getParent(grandchildParent);
        assertEq(grandchild, grandchildren[0]);
        assertEq(grandchildParent, child);
        assertEq(childParent, root);
        assertNotEq(root, child);
        assertNotEq(child, grandchild);
        assertNotEq(root, grandchild);
        // console2.logBytes32(root);
        // console2.logBytes32(child);
        // console2.logBytes32(grandchild);
    }

}
