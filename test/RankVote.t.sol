pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RankVote} from "../src/RankVote.sol";

import "forge-std/console.sol";

contract RankVoteHarness is RankVote {
    constructor(uint numProposals_) RankVote(numProposals_) {}

    function exposed_getActiveProposals() external view returns (uint256[] memory activeProposals) {
        return getActiveProposals();
    }

    function exposed_tiebreakWinner(
        uint256[] memory firstTally, 
        uint256[] memory lastTally, 
        uint256[] memory tiedProposals
    ) external view returns (uint256) {
        return tiebreakWinner(
            firstTally,
            lastTally,
            tiedProposals
        );
    }

    function exposed_tiebreakLoser(
        uint256[] memory firstTally, 
        uint256[] memory lastTally, 
        uint256[] memory tiedProposals
    ) external pure returns (uint256) {
        return tiebreakLoser(
            firstTally,
            lastTally,
            tiedProposals
        );
    }
        
    function exposed_finalize(
        uint256 numWinners
    ) external returns (uint256[] memory winners) {
        return super.finalize(numWinners);
    }
}

contract TestRankVote is Test {
    RankVoteHarness public rankVote;

    function setUp() public {
        rankVote = new RankVoteHarness(4);
    }

    function test_GetActiveProposals() public {
        addTestVotes();

        uint256[] memory activeProposals = rankVote.exposed_getActiveProposals();
        assertEq(activeProposals.length, 4);
        assertEq(activeProposals[0], 1);
        assertEq(activeProposals[1], 2);
        assertEq(activeProposals[2], 3);
        assertEq(activeProposals[3], 4);

        rankVote.eliminateProposal(1);

        activeProposals = rankVote.exposed_getActiveProposals();
        assertEq(activeProposals.length, 3);
        assertEq(activeProposals[0], 2);
        assertEq(activeProposals[1], 3);
        assertEq(activeProposals[2], 4);
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
        uint256 excessVotes = tally[1] - rankVote.droopQuota();
        tally = rankVote.distributeVotes(tally, 1, excessVotes);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);

        rankVote.eliminateProposal(2);
        excessVotes = tally[2] - rankVote.droopQuota();
        tally = rankVote.distributeVotes(tally, 2, excessVotes);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);
    }

    function test_FinalizeNotEnoughWinners() public {
        addTestVotes();

        uint256[] memory winners = rankVote.exposed_finalize(3);
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
    }

    function test_FinalizeEnoughWinners() public {
        addTestVotes();

        uint[] memory vote11 = new uint[](2);
        vote11[0] = 2;
        vote11[1] = 4;
        rankVote.addVote(vote11);

        uint[] memory vote12 = new uint[](1);
        vote12[0] = 2;
        rankVote.addVote(vote12);

        uint256[] memory winners = rankVote.exposed_finalize(3);
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    function test_FinalizeEnoughWinnersMany() public {
        for (uint256 i = 0; i < 1000; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 1;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 100; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 4;
            rankVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;
            rankVote.addVote(vote);
        }

        uint256[] memory winners = rankVote.exposed_finalize(3);
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    // Unit test
    function test_tiebreakWinnerByFirstTally() public {
        uint256[] memory firstTally = new uint256[](11);
        firstTally[1] = 119;
        firstTally[2] = 96;
        firstTally[3] = 754;
        firstTally[4] = 220;
        firstTally[5] = 278;
        firstTally[6] = 583;
        firstTally[7] = 198;
        firstTally[8] = 501;
        firstTally[9] = 480;
        firstTally[10] = 390;

        uint256[] memory lastTally = new uint256[](11);
        lastTally[1] = 133;
        lastTally[2] = 221;
        lastTally[3] = 754;
        lastTally[4] = 457;
        lastTally[5] = 406;
        lastTally[6] = 583;
        lastTally[7] = 198;
        lastTally[8] = 593;
        lastTally[9] = 502;
        lastTally[10] = 443;

        uint256[] memory tiedProposals = new uint256[](2);
        tiedProposals[0] = 6;
        tiedProposals[1] = 8;


        uint256 winner = rankVote.exposed_tiebreakWinner(firstTally, lastTally, tiedProposals);
        assertEq(winner, 6);
    }

    // Unit test
    function test_tiebreakWinnerByLastTally() public {
        uint256[] memory firstTally = new uint256[](11);
        firstTally[1] = 119;
        firstTally[2] = 96;
        firstTally[3] = 754;
        firstTally[4] = 220;
        firstTally[5] = 278;
        firstTally[6] = 583;
        firstTally[7] = 198;
        firstTally[8] = 583;
        firstTally[9] = 480;
        firstTally[10] = 390;

        uint256[] memory lastTally = new uint256[](11);
        lastTally[1] = 133;
        lastTally[2] = 221;
        lastTally[3] = 754;
        lastTally[4] = 457;
        lastTally[5] = 406;
        lastTally[6] = 583;
        lastTally[7] = 198;
        lastTally[8] = 593;
        lastTally[9] = 502;
        lastTally[10] = 443;

        uint256[] memory tiedProposals = new uint256[](2);
        tiedProposals[0] = 2;
        tiedProposals[1] = 7;


        uint256 winner = rankVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 2);
    }

    // Unit test
    function test_tiebreakLoserByFirstTally() public {
        uint256[] memory firstTally = new uint256[](11);
        firstTally[1] = 119;
        firstTally[2] = 96;
        firstTally[3] = 754;
        firstTally[4] = 220;
        firstTally[5] = 278;
        firstTally[6] = 583;
        firstTally[7] = 198;
        firstTally[8] = 583;
        firstTally[9] = 480;
        firstTally[10] = 390;

        uint256[] memory lastTally = new uint256[](11);
        lastTally[1] = 133;
        lastTally[2] = 221;
        lastTally[3] = 754;
        lastTally[4] = 457;
        lastTally[5] = 406;
        lastTally[6] = 583;
        lastTally[7] = 198;
        lastTally[8] = 593;
        lastTally[9] = 502;
        lastTally[10] = 443;

        uint256[] memory tiedProposals = new uint256[](2);
        tiedProposals[0] = 2;
        tiedProposals[1] = 7;


        uint256 winner = rankVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 2);
    }

    // Unit test
    function test_tiebreakLoserByLastTally() public {
        uint256[] memory firstTally = new uint256[](11);
        firstTally[1] = 119;
        firstTally[2] = 96;
        firstTally[3] = 754;
        firstTally[4] = 220;
        firstTally[5] = 278;
        firstTally[6] = 583;
        firstTally[7] = 96;
        firstTally[8] = 583;
        firstTally[9] = 480;
        firstTally[10] = 390;

        uint256[] memory lastTally = new uint256[](11);
        lastTally[1] = 133;
        lastTally[2] = 221;
        lastTally[3] = 754;
        lastTally[4] = 457;
        lastTally[5] = 406;
        lastTally[6] = 583;
        lastTally[7] = 198;
        lastTally[8] = 593;
        lastTally[9] = 502;
        lastTally[10] = 443;

        uint256[] memory tiedProposals = new uint256[](2);
        tiedProposals[0] = 2;
        tiedProposals[1] = 7;


        uint256 winner = rankVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 7);
    }

    /// @dev These numbers were spec'd so that after proposal 1 wins,
    ///      distributing its votes will cause a tie between 2 and 3.
    function test_finalizeWinnerTiebreakUsingFirstTally() public {
        rankVote = new RankVoteHarness(3);

        for (uint256 i = 0; i < 70; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 2;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 30; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 40; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 2;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 60; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 3;
            rankVote.addVote(vote);
        }

        uint256[] memory winners = rankVote.exposed_finalize(2);
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 3);
    }

    /// @dev These numbers were spec'd so that 3 and 4 start tied,
    ///      then after 1 wins, distributing 1's votes will give 
    ///      4 more votes, but then 2 wins next and after distributing 
    ///      2's votes we have another tie between 3 and 4.
    function test_finalizeWinnerTiebreakUsingLastTally() public {
        for (uint256 i = 0; i < 40; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 60; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 4;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 52; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 28; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 4;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 10; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 10; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 4;
            rankVote.addVote(vote);
        }

        uint256[] memory winners = rankVote.exposed_finalize(3);
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    /// @dev These numbers were spec'd so 3 has more first place votes than two, but after 1 wins and its votes are distributed, there is a tie in which 
    ///      then after 1 wins, distributing 1's votes will give 
    ///      4 more votes, but then 2 wins next and after distributing 
    ///      2's votes we have another tie between 3 and 4.
    function test_finalizeLoserTiebreakUsingFirstTally() public {
        rankVote = new RankVoteHarness(3);

        for (uint256 i = 0; i < 6; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 1;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 3; i++) {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 1; i++) {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 3;
            vote[2] = 2;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 4; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 3;
            rankVote.addVote(vote);
        }

        for (uint256 i = 0; i < 6; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 3;
            vote[1] = 2;
            rankVote.addVote(vote);
        }

        uint256[] memory winners = rankVote.exposed_finalize(2);
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 3);
    }

    function test_finalizeThreeWayTieInFirstTally() public {
        {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;

            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 2;
            vote[1] = 3;
            vote[2] = 1;

            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 3;
            vote[1] = 1;
            vote[2] = 2;

            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
            rankVote.addVote(vote);
        }

        uint256[] memory winners = rankVote.exposed_finalize(2);
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);

    }
}

