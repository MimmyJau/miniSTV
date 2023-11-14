
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StvExample} from "../src/examples/StvExample.sol";

import "forge-std/console.sol";

contract AddProposal is Test {
    StvExample public stvE;
    address alice;

    function setUp() public {
        stvE = new StvExample();

        alice = address(bytes20(keccak256(abi.encode("alice"))));

        stvE.suffrage(alice);
    }

    function test_AddOneProposal() public {
        string[] memory proposals_ = new string[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(1), "apple");
    }

    function test_AddFourProposals() public {
        string[] memory proposals_ = new string[](4);
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

    function test_AddMoreProposalsToExistingProposals() public {
        string[] memory proposals_ = new string[](4);
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
    
    function test_AddEmptyProposal() public {
        string[] memory proposals_ = new string[](1);
        proposals_[0] = "";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(0), "");
    }

    function testFail_AddProposalsAfterVotingStarts() public {
        string[] memory proposals_ = new string[](4);
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

    function testFail_AddProposalByUnauthorizedUser() public {
        string[] memory proposals_ = new string[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        vm.prank(alice);
        stvE.addProposals(proposals_);
    }

    function test_GetProposalNames() public {
        string[] memory proposals_ = new string[](4);
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

        string[] memory proposalName = stvE.getProposalNames();
        assertEq(proposalName.length, 9);
        assertEq(proposalName[1], "apple");
        assertEq(proposalName[2], "orange");
        assertEq(proposalName[3], "banana");
        assertEq(proposalName[4], "mango");
        assertEq(proposalName[5], "grapefruit");
        assertEq(proposalName[6], "kiwi");
        assertEq(proposalName[7], "blueberry");
        assertEq(proposalName[8], "watermelon");

    }
}

contract NumProposals is Test {
    StvExample public stvE;

    function setUp() public {
        stvE = new StvExample();

        string[] memory proposals_ = new string[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);
    }

    function test_NumProposals() public {
        assertEq(stvE.numProposals(), 4);
    }
}

contract Suffrage is Test {
    StvExample public stvE;
    address testAddr;

    function setUp() public {
        stvE = new StvExample();

        // test proposals
        string[] memory proposals_ = new string[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";
        stvE.addProposals(proposals_);

        // test address
        testAddr = address(bytes20(keccak256(abi.encode("spongebob"))));
    }

    function test_VotingWithSuffrage() public {
        stvE.suffrage(testAddr);
        stvE.start();

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_VotingWithSuffrageBeforeStart() public {
        stvE.suffrage(testAddr);

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_VotingWithSuffrageAfterEnd() public {
        stvE.suffrage(testAddr);
        stvE.start();
        stvE.end();

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_VotingWithoutSuffrage() public {
        stvE.start();

        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 2;
        vote[2] = 1;

        vm.prank(testAddr);
        stvE.vote(vote);
    }

    function testFail_VotingWithoutSuffrageBeforeStart() public {
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

    function test_Start() public {
        string[] memory proposals_ = new string[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        stvE.start();
    }

    function testFail_StartDisabledIfNoProposoals() public {
        stvE.start();
    }

    function testFail_StartCanOnlyBeCalledOnce() public {
        string[] memory proposals_ = new string[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        stvE.start();
        stvE.start();
    }

    function testFail_StartCanOnlyBeCalledByAuthorizedUserk() public {
        string[] memory proposals_ = new string[](1);
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
        string[] memory proposals_ = new string[](4);
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

    function test_VotesFromThreeUsers() public {
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

    function testFail_SameUserVotesTwice() public {
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

    function test_SubmitVoteWithOneChoice() public {
        uint256[] memory vote = new uint256[](1);
        vote[0] = 4;

        vm.prank(alice);
        stvE.vote(vote);
    }

    function test_SubmitVoteWithTwoChoices() public {
        uint256[] memory vote = new uint256[](2);
        vote[0] = 4;
        vote[1] = 3;

        vm.prank(bob);
        stvE.vote(vote);
    }

    function testFail_SubmitVoteWithFourChoices() public {
        uint256[] memory vote = new uint256[](4);
        vote[0] = 4;
        vote[1] = 3;
        vote[2] = 2;
        vote[3] = 1;

        vm.prank(carol);
        stvE.vote(vote);
    }

    function testFail_SubmitVoteWithDuplicateChoices() public {
        uint256[] memory vote = new uint256[](3);
        vote[0] = 4;
        vote[1] = 3;
        vote[2] = 4;

        vm.prank(bob);
        stvE.vote(vote);
    }

    function test_GetVote() public {
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

    function test_GetVoteBeforeVoting() public {
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

contract End is Test {
    StvExample public stvE;
    address[] users;
    address nonVotingUser;

    /// @dev This example vote is from wiki's STV page: https://archive.li/OGMBx
    function setUp() public {
        stvE = new StvExample();

        // proposals
        string[] memory proposals_ = new string[](7);
        proposals_[0] = "orange";
        proposals_[1] = "pear";
        proposals_[2] = "strawberry";
        proposals_[3] = "cake";
        proposals_[4] = "chocolate";
        proposals_[5] = "burger";
        proposals_[6] = "chicken";
        stvE.addProposals(proposals_);

        // address
        for (uint256 i = 0; i < 23; i++) {
            address a = address(bytes20(keccak256(abi.encode(i))));
            stvE.suffrage(a);
            users.push(a);
        }

        // grant suffrage to a user that doesn't vote
        {
            nonVotingUser = address(bytes20(keccak256(abi.encode("nonVotingUser"))));
            stvE.suffrage(nonVotingUser);
        }

        stvE.start();

        // votes
        uint256 iUser = 0;

        {
            uint256[] memory vote = new uint256[](2);
            vote[0] = 1;
            vote[1] = 2;

            for (uint256 i = 0; i < 3; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](3);
            vote[0] = 2;
            vote[1] = 3;
            vote[2] = 4;

            for (uint256 i = 0; i < 8; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](3);
            vote[0] = 3;
            vote[1] = 1;
            vote[2] = 2;

            for (uint256 i = 0; i < 1; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](2);
            vote[0] = 4;
            vote[1] = 5;

            for (uint256 i = 0; i < 3; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](3);
            vote[0] = 5;
            vote[1] = 4;
            vote[2] = 6;

            for (uint256 i = 0; i < 1; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](2);
            vote[0] = 6;
            vote[1] = 7;

            for (uint256 i = 0; i < 4; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }

        {
            uint256[] memory vote = new uint256[](3);
            vote[0] = 7;
            vote[1] = 5;
            vote[2] = 6;

            for (uint256 i = 0; i < 3; i++) {
                address user_ = users[iUser++];
                vm.prank(user_);
                stvE.vote(vote);
            }
        }
    }

    function test_End() public {
        uint256[] memory winners = stvE.end();
        assertEq(winners.length, 3);
        assertEq(winners[0], 2);
        assertEq(winners[1], 4);
        assertEq(winners[2], 6);
    }

    function test_GetWinners() public {
        stvE.end();

        uint256[] memory winners = stvE.winners();

        assertEq(winners.length, 3);
        assertEq(winners[0], 2);
        assertEq(winners[1], 4);
        assertEq(winners[2], 6);

    }

    function testFail_StartAfterVotingEnds() public {
        stvE.end();
        stvE.start();
    }

    function testFail_AddProposalAfterVotingEnds() public {
        stvE.end();

        string[] memory proposals_ = new string[](1);
        proposals_[0] = "mango";
        stvE.addProposals(proposals_);
    }

    function testFail_SuffrageAfterVotingEnds() public {
        stvE.end();
        address testAddr = address(bytes20(keccak256(abi.encode("spongebob"))));
        stvE.suffrage(testAddr);
    }

    function testFail_VotingAfterVotingEnds() public {
        stvE.end();

        uint256[] memory vote = new uint256[](2);
        vote[0] = 4;
        vote[1] = 5;

        vm.prank(nonVotingUser);
        stvE.vote(vote);
    }
}

