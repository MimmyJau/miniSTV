pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RankVote, Node} from "../src/RankVote.sol";
import "forge-std/console.sol";

contract TestRankVote is Test {
    RankVote public rankVote;

    function setUp() public {
        rankVote = new RankVote(4);
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


    function test_AddMultipleVotes() public {
        addTestVotes();

        bytes32 root = rankVote.getRoot();
        (uint rootProposal, uint rootVotes, uint rootCumulativeVotes) = rankVote.tree(root);
        assertEq(rootProposal, 0);
        assertEq(rootVotes, 0);
        assertEq(rootCumulativeVotes, 10);
        assertEq(rankVote.getChildren(root).length, 2);

        bytes32 node1 = rankVote.getChildren(root)[0];
        (uint node1Proposal, uint node1Votes, uint node1CumulativeVotes) = rankVote.tree(node1);
        assertEq(node1Proposal, 1);
        assertEq(node1Votes, 1);
        assertEq(node1CumulativeVotes, 9);
        assertEq(rankVote.getChildren(node1).length, 3);

        // To avoid "stack too deep" errors: https://ethereum.stackexchange.com/a/86514/127263
        {
            bytes32 node12 = rankVote.getChildren(node1)[0];
            (uint node12Proposal, uint node12Votes, uint node12CumulativeVotes) = rankVote.tree(node12);
            assertEq(node12Proposal, 2);
            assertEq(node12Votes, 2);
            assertEq(node12CumulativeVotes, 4);
            assertEq(rankVote.getChildren(node12).length, 2);

            bytes32 node124 = rankVote.getChildren(node12)[0];
            (uint node124Proposal, uint node124Votes, uint node124CumulativeVotes) = rankVote.tree(node124);
            assertEq(node124Proposal, 4);
            assertEq(node124Votes, 1);
            assertEq(node124CumulativeVotes, 1);
            assertEq(rankVote.getChildren(node124).length, 0);

            bytes32 node123 = rankVote.getChildren(node12)[1];
            (uint node123Proposal, uint node123Votes, uint node123CumulativeVotes) = rankVote.tree(node123);
            assertEq(node123Proposal, 3);
            assertEq(node123Votes, 1);
            assertEq(node123CumulativeVotes, 1);
            assertEq(rankVote.getChildren(node123).length, 0);
        }

        {
            bytes32 node13 = rankVote.getChildren(node1)[1];
            (uint node13Proposal, uint node13Votes, uint node13CumulativeVotes) = rankVote.tree(node13);
            assertEq(node13Proposal, 3);
            assertEq(node13Votes, 0);
            assertEq(node13CumulativeVotes, 1);
            assertEq(rankVote.getChildren(node13).length, 1);

            bytes32 node132 = rankVote.getChildren(node13)[0];
            (uint node132Proposal, uint node132Votes, uint node132CumulativeVotes) = rankVote.tree(node132);
            assertEq(node132Proposal, 2);
            assertEq(node132Votes, 1);
            assertEq(node132CumulativeVotes, 1);
            assertEq(rankVote.getChildren(node132).length, 0);
        }

        {
            bytes32 node14 = rankVote.getChildren(node1)[2];
            (uint node14Proposal, uint node14Votes, uint node14CumulativeVotes) = rankVote.tree(node14);
            assertEq(node14Proposal, 4);
            assertEq(node14Votes, 0);
            assertEq(node14CumulativeVotes, 3);
            assertEq(rankVote.getChildren(node14).length, 2);

            bytes32 node143 = rankVote.getChildren(node14)[0];
            (uint node143Proposal, uint node143Votes, uint node143CumulativeVotes) = rankVote.tree(node143);
            assertEq(node143Proposal, 3);
            assertEq(node143Votes, 2);
            assertEq(node143CumulativeVotes, 2);
            assertEq(rankVote.getChildren(node143).length, 0);

            bytes32 node142 = rankVote.getChildren(node14)[1];
            (uint node142Proposal, uint node142Votes, uint node142CumulativeVotes) = rankVote.tree(node142);
            assertEq(node142Proposal, 2);
            assertEq(node142Votes, 1);
            assertEq(node142CumulativeVotes, 1);
            assertEq(rankVote.getChildren(node142).length, 0);
        }

        bytes32 node2 = rankVote.getChildren(root)[1];
        (uint node2Proposal, uint node2Votes, uint node2CumulativeVotes) = rankVote.tree(node2);
        assertEq(node2Proposal, 2);
        assertEq(node2Votes, 1);
        assertEq(node2CumulativeVotes, 1);
        assertEq(rankVote.getChildren(node2).length, 0);
    }

    function test_tallyVotes() public {
        addTestVotes();
        
        uint[] memory tally = rankVote.tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 1);
        assertEq(tally[3], 0);
        assertEq(tally[4], 0);

        rankVote.eliminateProposal(1);
        tally = rankVote.tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 5);
        assertEq(tally[3], 1);
        assertEq(tally[4], 3);

        rankVote.eliminateProposal(2);
        tally = rankVote.tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 0);
        assertEq(tally[3], 2);
        assertEq(tally[4], 4);

        rankVote.eliminateProposal(4);
        tally = rankVote.tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 0);
        assertEq(tally[3], 4);
        assertEq(tally[4], 0);
    }
    
    function test_TotalVotes() public {
        addTestVotes();

        uint totalVotes = rankVote.totalVotes();
        assertEq(totalVotes, 10);
    }

    function test_DroopQuota() public {
        addTestVotes();

        uint quota = rankVote.droopQuota();
        assertEq(quota, 3);
    }

    function test_DistributeVotes() public {
        addTestVotes();

        uint[] memory tally = rankVote.tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 1);
        assertEq(tally[3], 0);
        assertEq(tally[4], 0);

        rankVote.eliminateProposal(1);
        tally = rankVote.distributeVotes(tally, 1);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);

        rankVote.eliminateProposal(2);
        tally = rankVote.distributeVotes(tally, 2);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);
    }

    function test_AddVoteWithDuplicates() public {
        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 3;
        vote[2] = 1;
        vm.expectRevert();
        rankVote.addVote(vote);
    }
}
