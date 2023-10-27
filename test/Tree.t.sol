// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Tree, Node} from "../src/Tree.sol";

contract TreeTest is Test {
    Tree public tree;

    function setUp() public {
        tree = new Tree();
    }

    function test_Root() public {
        bytes32 root = tree.getRoot();
        assertEq(root, bytes32(0));
    }

    function test_OneChild() public {
        bytes32 root = tree.getRoot();
        bytes32 child = tree.addChild(root);
        bytes32[] memory rootChildren = tree.getChildren(root);
        bytes32 childParent = tree.getParent(child);
        assertEq(child, rootChildren[0]);
        assertEq(childParent, root);
        assertNotEq(root, child);
    }

    function test_TwoChildren() public {
        bytes32 root = tree.getRoot();
        bytes32 child = tree.addChild(root);
        bytes32 child2 = tree.addChild(root);
        bytes32[] memory rootChildren = tree.getChildren(root);
        bytes32 childParent = tree.getParent(child);
        bytes32 child2Parent = tree.getParent(child2);
        assertEq(child, rootChildren[0]);
        assertEq(childParent, root);
        assertEq(child2, rootChildren[1]);
        assertEq(child2Parent, root);
        assertNotEq(child, child2);
    }

    function test_GrandChild() public {
        bytes32 root = tree.getRoot();
        bytes32 child = tree.addChild(root);
        bytes32 grandchild = tree.addChild(child);
        bytes32[] memory children = tree.getChildren(root);
        bytes32[] memory grandchildren = tree.getChildren(children[0]);
        bytes32 grandchildParent = tree.getParent(grandchildren[0]);
        bytes32 childParent = tree.getParent(grandchildParent);
        assertEq(grandchild, grandchildren[0]);
        assertEq(grandchildParent, child);
        assertEq(childParent, root);
        assertNotEq(root, child);
        assertNotEq(child, grandchild);
        assertNotEq(root, grandchild);
    }

}
