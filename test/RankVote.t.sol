pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RankVote, Node} from "../src/RankVote.sol";

import "forge-std/console.sol";

contract RankVoteHarness is RankVote {
    constructor() RankVote() {}

    ////////////////////////////////////////////////////////////////////////
    // Inherited functions from Tree

    function exposed_getRoot() external view returns (bytes32) {
        return getRoot();
    }

    function exposed_getChildren(bytes32 parent) external view returns (bytes32[] memory) {
        return getChildren(parent);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions and state from RankVote

    function exposed_Tree(
        bytes32 node32
    ) external view returns (
        uint256 proposal,
        uint256 votes,
        uint256 cumulativeVotes
    ) {
        return (
            tree[node32].proposal,
            tree[node32].votes,
            tree[node32].cumulativeVotes
        );
    }

    function exposed_totalVotes() external view returns(uint256 voteCount) {
        return totalVotes();
    }

}

contract TestRankVote is Test {
    RankVoteHarness public rankVote;

    function setUp() public {
        rankVote = new RankVoteHarness();
    }

    function test_AddVote() public {
        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 2;
        vote[2] = 3;
        rankVote.addVote(vote);

        bytes32 root = rankVote.exposed_getRoot();
        (uint rootProposal, uint rootVotes, uint rootCumulativeVotes) = rankVote.exposed_Tree(root);
        assertEq(rootProposal, 0);
        assertEq(rootVotes, 0);
        assertEq(rootCumulativeVotes, 1);
        assertEq(rankVote.exposed_getChildren(root).length, 1);

        bytes32 child1 = rankVote.exposed_getChildren(root)[0];
        (uint child1Proposal, uint child1Votes, uint child1CumulativeVotes) = rankVote.exposed_Tree(child1);
        assertEq(child1Proposal, 1);
        assertEq(child1Votes, 0);
        assertEq(child1CumulativeVotes, 1);
        assertEq(rankVote.exposed_getChildren(child1).length, 1);

        bytes32 child2 = rankVote.exposed_getChildren(child1)[0];
        (uint child2Proposal, uint child2Votes, uint child2CumulativeVotes) = rankVote.exposed_Tree(child2);
        assertEq(child2Proposal, 2);
        assertEq(child2Votes, 0);
        assertEq(child2CumulativeVotes, 1);
        assertEq(rankVote.exposed_getChildren(child2).length, 1);

        bytes32 child3 = rankVote.exposed_getChildren(child2)[0];
        (uint child3Proposal, uint child3Votes, uint child3CumulativeVotes) = rankVote.exposed_Tree(child3);
        assertEq(child3Proposal, 3);
        assertEq(child3Votes, 1);
        assertEq(child3CumulativeVotes, 1);
        assertEq(rankVote.exposed_getChildren(child3).length, 0);
    }

    function test_AddVoteWithDuplicates() public {
        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 3;
        vote[2] = 1;
        vm.expectRevert();
        rankVote.addVote(vote);
    }

    function addTestVotes() private {
        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 2;
        vote[2] = 4;
        rankVote.addVote(vote);

        uint[] memory vote2 = new uint[](3);
        vote2[0] = 1;
        vote2[1] = 3;
        vote2[2] = 2;
        rankVote.addVote(vote2);

        uint[] memory vote3 = new uint[](3);
        vote3[0] = 1;
        vote3[1] = 4;
        vote3[2] = 3;
        rankVote.addVote(vote3);

        uint[] memory vote4 = new uint[](3);
        vote4[0] = 1;
        vote4[1] = 4;
        vote4[2] = 3;
        rankVote.addVote(vote4);

        uint[] memory vote5 = new uint[](3);
        vote5[0] = 1;
        vote5[1] = 4;
        vote5[2] = 2;
        rankVote.addVote(vote5);

        uint[] memory vote6 = new uint[](3);
        vote6[0] = 1;
        vote6[1] = 2;
        vote6[2] = 3;
        rankVote.addVote(vote6);

        uint[] memory vote7 = new uint[](2);
        vote7[0] = 1;
        vote7[1] = 2;
        rankVote.addVote(vote7);

        uint[] memory vote8 = new uint[](2);
        vote8[0] = 1;
        vote8[1] = 2;
        rankVote.addVote(vote8);

        uint[] memory vote9 = new uint[](1);
        vote9[0] = 1;
        rankVote.addVote(vote9);

        uint[] memory vote10 = new uint[](1);
        vote10[0] = 2;
        rankVote.addVote(vote10);

    }

    function test_TotalVotes() public {
        addTestVotes();

        uint totalVotes = rankVote.exposed_totalVotes();
        assertEq(totalVotes, 10);
    }

    function test_AddMultipleVotes() public {
        addTestVotes();

        bytes32 root = rankVote.exposed_getRoot();
        (uint rootProposal, uint rootVotes, uint rootCumulativeVotes) = rankVote.exposed_Tree(root);
        assertEq(rootProposal, 0);
        assertEq(rootVotes, 0);
        assertEq(rootCumulativeVotes, 10);
        assertEq(rankVote.exposed_getChildren(root).length, 2);

        bytes32 node1 = rankVote.exposed_getChildren(root)[0];
        (uint node1Proposal, uint node1Votes, uint node1CumulativeVotes) = rankVote.exposed_Tree(node1);
        assertEq(node1Proposal, 1);
        assertEq(node1Votes, 1);
        assertEq(node1CumulativeVotes, 9);
        assertEq(rankVote.exposed_getChildren(node1).length, 3);

        // To avoid "stack too deep" errors: https://ethereum.stackexchange.com/a/86514/127263
        {
            bytes32 node12 = rankVote.exposed_getChildren(node1)[0];
            (uint node12Proposal, uint node12Votes, uint node12CumulativeVotes) = rankVote.exposed_Tree(node12);
            assertEq(node12Proposal, 2);
            assertEq(node12Votes, 2);
            assertEq(node12CumulativeVotes, 4);
            assertEq(rankVote.exposed_getChildren(node12).length, 2);

            bytes32 node124 = rankVote.exposed_getChildren(node12)[0];
            (uint node124Proposal, uint node124Votes, uint node124CumulativeVotes) = rankVote.exposed_Tree(node124);
            assertEq(node124Proposal, 4);
            assertEq(node124Votes, 1);
            assertEq(node124CumulativeVotes, 1);
            assertEq(rankVote.exposed_getChildren(node124).length, 0);

            bytes32 node123 = rankVote.exposed_getChildren(node12)[1];
            (uint node123Proposal, uint node123Votes, uint node123CumulativeVotes) = rankVote.exposed_Tree(node123);
            assertEq(node123Proposal, 3);
            assertEq(node123Votes, 1);
            assertEq(node123CumulativeVotes, 1);
            assertEq(rankVote.exposed_getChildren(node123).length, 0);
        }

        {
            bytes32 node13 = rankVote.exposed_getChildren(node1)[1];
            (uint node13Proposal, uint node13Votes, uint node13CumulativeVotes) = rankVote.exposed_Tree(node13);
            assertEq(node13Proposal, 3);
            assertEq(node13Votes, 0);
            assertEq(node13CumulativeVotes, 1);
            assertEq(rankVote.exposed_getChildren(node13).length, 1);

            bytes32 node132 = rankVote.exposed_getChildren(node13)[0];
            (uint node132Proposal, uint node132Votes, uint node132CumulativeVotes) = rankVote.exposed_Tree(node132);
            assertEq(node132Proposal, 2);
            assertEq(node132Votes, 1);
            assertEq(node132CumulativeVotes, 1);
            assertEq(rankVote.exposed_getChildren(node132).length, 0);
        }

        {
            bytes32 node14 = rankVote.exposed_getChildren(node1)[2];
            (uint node14Proposal, uint node14Votes, uint node14CumulativeVotes) = rankVote.exposed_Tree(node14);
            assertEq(node14Proposal, 4);
            assertEq(node14Votes, 0);
            assertEq(node14CumulativeVotes, 3);
            assertEq(rankVote.exposed_getChildren(node14).length, 2);

            bytes32 node143 = rankVote.exposed_getChildren(node14)[0];
            (uint node143Proposal, uint node143Votes, uint node143CumulativeVotes) = rankVote.exposed_Tree(node143);
            assertEq(node143Proposal, 3);
            assertEq(node143Votes, 2);
            assertEq(node143CumulativeVotes, 2);
            assertEq(rankVote.exposed_getChildren(node143).length, 0);

            bytes32 node142 = rankVote.exposed_getChildren(node14)[1];
            (uint node142Proposal, uint node142Votes, uint node142CumulativeVotes) = rankVote.exposed_Tree(node142);
            assertEq(node142Proposal, 2);
            assertEq(node142Votes, 1);
            assertEq(node142CumulativeVotes, 1);
            assertEq(rankVote.exposed_getChildren(node142).length, 0);
        }

        bytes32 node2 = rankVote.exposed_getChildren(root)[1];
        (uint node2Proposal, uint node2Votes, uint node2CumulativeVotes) = rankVote.exposed_Tree(node2);
        assertEq(node2Proposal, 2);
        assertEq(node2Votes, 1);
        assertEq(node2CumulativeVotes, 1);
        assertEq(rankVote.exposed_getChildren(node2).length, 0);
    }
}

