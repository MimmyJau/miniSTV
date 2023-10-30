// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RankVote, Node} from "../src/RankVote.sol";
import "forge-std/console.sol";

contract TestRankVote is Test {
    RankVote public rankVote;

    function setUp() public {
        rankVote = new RankVote();
    }

    function test_AddVote() public {
        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 2;
        vote[2] = 3;
        rankVote.addVote(vote);

        bytes32 root = rankVote.getRoot();
        (uint rootProposal, uint rootVotes, uint rootCumulativeVotes) = rankVote.tree(root);
        assertEq(rootProposal, 0);
        assertEq(rootVotes, 0);
        assertEq(rootCumulativeVotes, 1);
        assertEq(rankVote.getChildren(root).length, 1);

        bytes32 child1 = rankVote.getChildren(root)[0];
        (uint child1Proposal, uint child1Votes, uint child1CumulativeVotes) = rankVote.tree(child1);
        assertEq(child1Proposal, 1);
        assertEq(child1Votes, 0);
        assertEq(child1CumulativeVotes, 1);
        assertEq(rankVote.getChildren(child1).length, 1);

        bytes32 child2 = rankVote.getChildren(child1)[0];
        (uint child2Proposal, uint child2Votes, uint child2CumulativeVotes) = rankVote.tree(child2);
        assertEq(child2Proposal, 2);
        assertEq(child2Votes, 0);
        assertEq(child2CumulativeVotes, 1);
        assertEq(rankVote.getChildren(child2).length, 1);

        bytes32 child3 = rankVote.getChildren(child2)[0];
        (uint child3Proposal, uint child3Votes, uint child3CumulativeVotes) = rankVote.tree(child3);
        assertEq(child3Proposal, 3);
        assertEq(child3Votes, 1);
        assertEq(child3CumulativeVotes, 1);
        assertEq(rankVote.getChildren(child3).length, 0);
    }
}
