
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StvExample} from "../src/StvExample.sol";

import "forge-std/console.sol";

contract AddProposal is Test {
    StvExample public stvE;

    function test_addOneProposal() public {
        stvE = new StvExample();

        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "apple";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(1), "apple");
    }

    function test_addFourProposals() public {
        stvE = new StvExample();

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

    function test_addEmptyProposal() public {
        stvE = new StvExample();

        bytes[] memory proposals_ = new bytes[](1);
        proposals_[0] = "";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(0), "");
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


}
