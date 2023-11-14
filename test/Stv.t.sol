pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Stv} from "../src/Stv.sol";

import "forge-std/console.sol";

contract StvHarness is Stv {
    constructor(
        uint256 numProposals_, 
        uint256 numWinners_
    ) Stv(numProposals_, numWinners_) {}

    function exposed_eliminateProposal(uint256 proposal) external {
        return eliminateProposal(proposal);
    }

    function exposed_getActiveProposals() external view returns (uint256[] memory activeProposals) {
        return getActiveProposals();
    }

    function exposed_droopQuota() external view returns (uint256) {
        return droopQuota();
    }

    function exposed_distributeVotes(
        uint256[] memory tally, 
        uint256 dProposal,
        uint256 excessVotes
    ) external returns (uint[] memory) {
        return distributeVotes(tally, dProposal, excessVotes);
    }

    function exposed_tallyVotes() external view returns (uint[] memory tally) {
        return tallyVotes();
    }

    function exposed_tiebreakWinner(
        uint256[] memory firstTally, 
        uint256[] memory lastTally, 
        uint256[] memory tiedProposals
    ) external pure returns (uint256) {
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
    ) external returns (uint256[] memory winners) {
        return super.finalize();
    }
}

contract TestStv is Test {
    StvHarness public stvVote;

    function setUp() public {
    }

    function addTestVotes() private {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        uint[] memory vote = new uint[](3);
        vote[0] = 1;
        vote[1] = 2;
        vote[2] = 4;
        stvVote.addVote(vote);

        uint[] memory vote2 = new uint[](3);
        vote2[0] = 1;
        vote2[1] = 3;
        vote2[2] = 2;
        stvVote.addVote(vote2);

        uint[] memory vote3 = new uint[](3);
        vote3[0] = 1;
        vote3[1] = 4;
        vote3[2] = 3;
        stvVote.addVote(vote3);

        uint[] memory vote4 = new uint[](3);
        vote4[0] = 1;
        vote4[1] = 4;
        vote4[2] = 3;
        stvVote.addVote(vote4);

        uint[] memory vote5 = new uint[](3);
        vote5[0] = 1;
        vote5[1] = 4;
        vote5[2] = 2;
        stvVote.addVote(vote5);

        uint[] memory vote6 = new uint[](3);
        vote6[0] = 1;
        vote6[1] = 2;
        vote6[2] = 3;
        stvVote.addVote(vote6);

        uint[] memory vote7 = new uint[](2);
        vote7[0] = 1;
        vote7[1] = 2;
        stvVote.addVote(vote7);

        uint[] memory vote8 = new uint[](2);
        vote8[0] = 1;
        vote8[1] = 2;
        stvVote.addVote(vote8);

        uint[] memory vote9 = new uint[](1);
        vote9[0] = 1;
        stvVote.addVote(vote9);

        uint[] memory vote10 = new uint[](1);
        vote10[0] = 2;
        stvVote.addVote(vote10);

    }

    function test_GetActiveProposals() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();

        uint256[] memory activeProposals = stvVote.exposed_getActiveProposals();
        assertEq(activeProposals.length, 4);
        assertEq(activeProposals[0], 1);
        assertEq(activeProposals[1], 2);
        assertEq(activeProposals[2], 3);
        assertEq(activeProposals[3], 4);

        stvVote.exposed_eliminateProposal(1);

        activeProposals = stvVote.exposed_getActiveProposals();
        assertEq(activeProposals.length, 3);
        assertEq(activeProposals[0], 2);
        assertEq(activeProposals[1], 3);
        assertEq(activeProposals[2], 4);
    }

    function test_exposed_tallyVotes() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();
        
        uint[] memory tally = stvVote.exposed_tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 1);
        assertEq(tally[3], 0);
        assertEq(tally[4], 0);

        stvVote.exposed_eliminateProposal(1);
        tally = stvVote.exposed_tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 5);
        assertEq(tally[3], 1);
        assertEq(tally[4], 3);

        stvVote.exposed_eliminateProposal(2);
        tally = stvVote.exposed_tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 0);
        assertEq(tally[3], 2);
        assertEq(tally[4], 4);

        stvVote.exposed_eliminateProposal(4);
        tally = stvVote.exposed_tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 0);
        assertEq(tally[2], 0);
        assertEq(tally[3], 4);
        assertEq(tally[4], 0);
    }

    function test_DroopQuota() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();

        uint quota = stvVote.exposed_droopQuota();
        assertEq(quota, 3);
    }

    function test_DistributeVotes() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();

        uint[] memory tally = stvVote.exposed_tallyVotes();
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 1);
        assertEq(tally[3], 0);
        assertEq(tally[4], 0);

        stvVote.exposed_eliminateProposal(1);
        uint256 excessVotes = tally[1] - stvVote.exposed_droopQuota();
        tally = stvVote.exposed_distributeVotes(tally, 1, excessVotes);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);

        stvVote.exposed_eliminateProposal(2);
        excessVotes = tally[2] - stvVote.exposed_droopQuota();
        tally = stvVote.exposed_distributeVotes(tally, 2, excessVotes);
        assertEq(tally.length, 5);
        assertEq(tally[0], 0);
        assertEq(tally[1], 9);
        assertEq(tally[2], 4);
        assertEq(tally[3], 0);
        assertEq(tally[4], 2);
    }

    function test_FinalizeNotEnoughWinners() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
    }

    function test_FinalizeEnoughWinners() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        addTestVotes();

        {
            uint[] memory vote11 = new uint[](2);
            vote11[0] = 2;
            vote11[1] = 4;
            stvVote.addVote(vote11);

            uint[] memory vote12 = new uint[](1);
            vote12[0] = 2;
            stvVote.addVote(vote12);
        }

        {
            uint[] memory vote = new uint[](1);
            vote[0] = 1;
            for (uint256 i = 0; i < 3; i++) {
                stvVote.addVote(vote);
            }

        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    function test_FinalizeEnoughWinnersMany() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        for (uint256 i = 0; i < 1000; i++) {
            uint[] memory vote = new uint[](1);
            vote[0] = 1;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 100; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 4;
            stvVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;
            stvVote.addVote(vote);
        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    // Unit test
    function test_tiebreakWinnerByFirstTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

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


        uint256 winner = stvVote.exposed_tiebreakWinner(firstTally, lastTally, tiedProposals);
        assertEq(winner, 6);
    }

    // Unit test
    function test_tiebreakWinnerByLastTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

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


        uint256 winner = stvVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 2);
    }

    // Unit test
    function test_tiebreakLoserByFirstTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

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


        uint256 winner = stvVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 2);
    }

    // Unit test
    function test_tiebreakLoserByLastTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

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


        uint256 winner = stvVote.exposed_tiebreakLoser(firstTally, lastTally, tiedProposals);
        assertEq(winner, 7);
    }

    /// @dev These numbers were spec'd so that after proposal 1 wins,
    ///      distributing its votes will cause a tie between 2 and 3.
    function test_finalizeWinnerTiebreakUsingFirstTally() public {
        uint256 numProposals = 3;
        uint256 numWinners = 2;
        stvVote = new StvHarness(numProposals, numWinners);

        for (uint256 i = 0; i < 70; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 2;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 30; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 3;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 43; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 3;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 57; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 3;
            vote[1] = 2;
            stvVote.addVote(vote);
        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 3);
    }

    /// @dev These numbers were spec'd so that 3 and 4 start tied,
    ///      then after 1 wins, distributing 1's votes will give 
    ///      4 more votes, but then 2 wins next and after distributing 
    ///      2's votes we have another tie between 3 and 4.
    function test_finalizeWinnerTiebreakUsingLastTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        for (uint256 i = 0; i < 40; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 3;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 60; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 4;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 53; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 3;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 27; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 2;
            vote[1] = 4;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 10; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 3;
            vote[1] = 4;
            stvVote.addVote(vote);
        }

        for (uint256 i = 0; i < 10; i++) {
            uint[] memory vote = new uint[](2);
            vote[0] = 4;
            vote[1] = 3;
            stvVote.addVote(vote);
        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    /// @dev These numbers were spec'd so 3 has more first place votes than 4, 
    ///      but after 1 and 2 win and their votes are distributed, there is a 
    ///      tie between 3 and 4. 4 wins the tiebreak and 3's votes transferred.
    function test_finalizeLoserTiebreakUsingFirstTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);

        {
            uint[] memory vote = new uint[](4);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;
            vote[3] = 4;
            for (uint256 i = 0; i < 6; i++) {
                stvVote.addVote(vote);
            }
        }

        {
            uint[] memory vote = new uint[](4);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 4;
            vote[3] = 3;
            for (uint256 i = 0; i < 3; i++) {
                stvVote.addVote(vote);
            }
        }

        {
            uint[] memory vote = new uint[](1);
            vote[0] = 4;
            stvVote.addVote(vote);
        }


        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);
    }

    /// @dev These numbers were spec'd so both 3 and 4 have no first-rank votes,
    ///      but after 1 wins and its votes are distributed, 4 has more votes than 3, 
    ///      but after 2 wins and its votes are distributed, there is another tie.
    function test_finalizeLoserTiebreakUsingLastTally() public {
        uint256 numProposals = 4;
        uint256 numWinners = 3;
        stvVote = new StvHarness(numProposals, numWinners);
        
        {
            uint[] memory vote = new uint[](4);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 4;
            vote[3] = 3;
            for (uint256 i = 0; i < 2; i++) {
                stvVote.addVote(vote);
            }
        }

        {
            uint[] memory vote = new uint[](4);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;
            vote[3] = 4;
            for (uint256 i = 0; i < 4; i++) {
                stvVote.addVote(vote);
            }
        }

        {
            uint[] memory vote = new uint[](2);
            vote[0] = 1;
            vote[1] = 4;
            for (uint256 i = 0; i < 1; i++) {
                stvVote.addVote(vote);
            }
        }

        {
            uint[] memory vote = new uint[](1);
            vote[0] = 1;
            for (uint256 i = 0; i < 3; i++) {
                stvVote.addVote(vote);
            }
        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 3);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);
        assertEq(winners[2], 4);

    }

    /// @dev These numbers were spec'd so there would be a 3-way tie that cannot
    ///      be broken by a tiebreaker. 
    function test_finalizeThreeWayTieInFirstTally() public {
        uint256 numProposals = 3;
        uint256 numWinners = 2;
        stvVote = new StvHarness(numProposals, numWinners);

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 1;
            vote[1] = 2;
            vote[2] = 3;

            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 2;
            vote[1] = 3;
            vote[2] = 1;

            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
        }

        {
            uint[] memory vote = new uint[](3);
            vote[0] = 3;
            vote[1] = 1;
            vote[2] = 2;

            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
            stvVote.addVote(vote);
        }

        uint256[] memory winners = stvVote.exposed_finalize();
        assertEq(winners.length, 2);
        assertEq(winners[0], 1);
        assertEq(winners[1], 2);

    }
}
