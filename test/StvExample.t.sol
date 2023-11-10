
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StvExample} from "../src/StvExample.sol";

import "forge-std/console.sol";

contract TestStv is Test {
    StvExample public stvE;

    function setUp() public {
        stvE = new StvExample();
    }

    function test_addProposals() public {
        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);

        assertEq(stvE.proposals(0), "apple");
        assertEq(stvE.proposals(1), "orange");
        assertEq(stvE.proposals(2), "banana");
        assertEq(stvE.proposals(3), "mango");
    }

    function test_numProposals() public {
        assertEq(stvE.numProposals(), 0);

        bytes[] memory proposals_ = new bytes[](4);
        proposals_[0] = "apple";
        proposals_[1] = "orange";
        proposals_[2] = "banana";
        proposals_[3] = "mango";

        stvE.addProposals(proposals_);

        assertEq(stvE.numProposals(), 4);
    }

}
