
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StvExample} from "../src/StvExample.sol";

import "forge-std/console.sol";

contract AddProposal is Test {
    StvExample public stvE;
    address alice;

    function setUp() public {
        stvE = new StvExample();

        alice = address(bytes20(keccak256(abi.encode("alice"))));

        stvE.suffrage(alice);
    }

    function test_addOneProposal() public {
        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(1), "apple");
    }

    function test_addFourProposals() public {
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(1), "apple");
        assertEq(stvE.proposals(2), "orange");
        assertEq(stvE.proposals(3), "banana");
        assertEq(stvE.proposals(4), "mango");
    }

    function test_addMoreProposalsToExistingProposals() public {
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);

        proposals_[0] = "grapefruit";
        proposals_[1] = "kiwi";
        proposals_[2] = "blueberry";
        proposals_[3] = "watermelon";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(1), "apple");
        assertEq(stvE.proposals(2), "orange");
        assertEq(stvE.proposals(3), "banana");
        assertEq(stvE.proposals(4), "mango");
        assertEq(stvE.proposals(5), "grapefruit");
        assertEq(stvE.proposals(6), "kiwi");
        assertEq(stvE.proposals(7), "blueberry");
        assertEq(stvE.proposals(8), "watermelon");
    }
    
    function test_addEmptyProposal() public {
        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(0), "");
    }

    function testFail_addProposalsAfterVotingStarts() public {
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);

        stvE.start();

        proposals_[0] = "grapefruit";
        proposals_[1] = "kiwi";
        proposals_[2] = "blueberry";
        proposals_[3] = "watermelon";

        stvE.addProposals(proposals_);
    }

    function testFail_addProposalByUnauthorizedUser() public {
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        vm.prank(alice);
        stvE.addProposals(proposals_);
    }
}

contract NumProposals is Test {
    StvExample public stvE;

    function setUp() public {
        stvE = new StvExample();

        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);
    }

    function test_numProposals() public {
        assertEq(stvE.numProposals(), 4);
    }
}

contract Suffrage is Test {
    StvExample public stvE;
    address testAddr;

    function setUp() public {
        stvE = new StvExample();

        // test proposals
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";
        stvE.addProposals(proposals_);

        // test address
        testAddr = address(bytes20(keccak256(abi.encode("spongebob"))));
    }

    function test_votingWithSuffrage() public {
        stvE.suffrage(testAddr);
        stvE.start();

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_votingWithSuffrageBeforeStart() public {
        stvE.suffrage(testAddr);

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_votingWithSuffrageAfterEnd() public {
        stvE.suffrage(testAddr);
        stvE.start();
        stvE.end(1);

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_votingWithoutSuffrage() public {
        stvE.start();

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_votingWithoutSuffrageBeforeStart() public {
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }
}


contract Start is Test {
    StvExample public stvE;
    address alice;

    function setUp() public {
        stvE = new StvExample();

        alice = address(bytes20(keccak256(abi.encode("alice"))));

        stvE.suffrage(alice);
    }

    function test_start() public {
        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        stvE.start();
    }

    function testFail_startDisabledIfNoProposoals() public {
        stvE.start();
    }

    function testFail_startCanOnlyBeCalledOnce() public {
        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        stvE.start();
        stvE.start();
    }

    function testFail_startCanOnlyBeCalledByAuthorizedUserk() public {
        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        vm.prank(alice);
        stvE.start();
    }
}

contract Vote is Test {
    StvExample public stvE;
    address alice;
    address bob;
    address carol;


    function setUp() public {
        stvE = new StvExample();

        // test proposals
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";
        stvE.addProposals(proposals_);

        // test address
        alice = address(bytes20(keccak256(abi.encode("alice"))));
        bob = address(bytes20(keccak256(abi.encode("bob"))));
        carol = address(bytes20(keccak256(abi.encode("carol"))));

        stvE.suffrage(alice);
        stvE.suffrage(bob);
        stvE.suffrage(carol);

        stvE.start();
    }

    function test_votesFromThreeUsers() public {
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(alice);
        stvE.vote(vote);

        vote[0] = 1;
        vote[1] = 3;
        vote[2] = 2;

        vm.prank(bob);
        stvE.vote(vote);

        vote[0] = 3;
        vote[1] = 4;
        vote[2] = 1;

        vm.prank(carol);
        stvE.vote(vote);
    }

    function testFail_sameUserVotesTwice() public {
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(alice);
        stvE.vote(vote);

        vote[0] = 1;
        vote[1] = 3;
        vote[2] = 2;

        vm.prank(alice);
        stvE.vote(vote);
    }

    function test_submitVoteWithOneChoice() public {
        uint256[] memory vote = new uint256[](1);
        vote[0] = 4;

        vm.prank(alice);
        stvE.vote(vote);
    }

    function test_submitVoteWithTwoChoices() public {
        uint256[] memory vote = new uint256[](2);
        vote[0] = 4;
        vote[1] = 3;

        vm.prank(bob);
        stvE.vote(vote);
    }

    function testFail_submitVoteWithFourChoices() public {
        uint256[] memory vote = new uint256[](4);
        vote[0] = 4;
        vote[1] = 3;
        vote[2] = 2;
        vote[3] = 1;

        vm.prank(carol);
        stvE.vote(vote);
    }

    function testFail_submitVoteWithDuplicateChoices() public {
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 3;
        vote[2] = 4;

        vm.prank(bob);
        stvE.vote(vote);
    }

    function test_getVote() public {
        // add alice's vote
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(alice);
        stvE.vote(vote);

        // add bob's vote
        vote[0] = 1;
        vote[1] = 3;
        vote[2] = 2;

        vm.prank(bob);
        stvE.vote(vote);

        // get alice's vote
        vm.prank(alice);
        vote = stvE.getVote();

        assertEq(vote.length, 3);
        assertEq(vote[0], 4);
        assertEq(vote[1], 2);
        assertEq(vote[2], 1);

        // get bob's vote
        vm.prank(bob);
        vote = stvE.getVote();

        assertEq(vote.length, 3);
        assertEq(vote[0], 1);
        assertEq(vote[1], 3);
        assertEq(vote[2], 2);

    }

    function test_getVoteBeforeVoting() public {
        uint256[] memory vote = new uint256[](3);
        
        // get alice's vote
        vm.prank(alice);
        vote = stvE.getVote();

        assertEq(vote.length, 0);

        // get bob's vote
        vm.prank(bob);
        vote = stvE.getVote();

        assertEq(vote.length, 0);

    }

}
