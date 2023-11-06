pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ArrayMaxMin} from "../src/libraries/ArrayMaxMin.sol";

contract TestArrayMaxMin is Test {
    using ArrayMaxMin for uint256[];

    function test_GetSingleMaximalValue() public {
        uint256[] memory testArray = new uint256[](10);
        testArray[1] = 5;
        testArray[2] = 9;
        testArray[3] = 15;
        testArray[4] = 15;
        testArray[5] = 15;
        testArray[6] = 15;
        testArray[7] = 33;
        testArray[8] = 20;
        testArray[9] = 2;

        uint256[] memory maxTally = testArray.maxTally();
        assertEq(maxTally.length, 1);
        assertEq(maxTally[0], 7);
    }

    function test_GetMultipleMaximalValues() public {
        uint256[] memory testArray = new uint256[](10);
        testArray[1] = 5;
        testArray[2] = 9;
        testArray[3] = 15;
        testArray[4] = 1000;
        testArray[5] = 3;
        testArray[6] = 1000;
        testArray[7] = 1000;
        testArray[8] = 15;
        testArray[9] = 2;

        uint256[] memory maxTally = testArray.maxTally();
        assertEq(maxTally.length, 3);
        assertEq(maxTally[0], 4);
        assertEq(maxTally[1], 6);
        assertEq(maxTally[2], 7);
    }

    function test_GetSingleMaximalValueFromSubset() public {
        uint256[] memory testArray = new uint256[](10);
        testArray[1] = 5;
        testArray[2] = 9;
        testArray[3] = 15;
        testArray[4] = 20;
        testArray[5] = 33;
        testArray[6] = 15;
        testArray[7] = 20;
        testArray[8] = 15;
        testArray[9] = 2;

        uint256[] memory subset = new uint256[](5);
        subset[0] = 1;
        subset[1] = 2;
        subset[2] = 4;
        subset[3] = 6;
        subset[4] = 9;

        uint256[] memory maxTally = testArray.maxSubset(subset);
        assertEq(maxTally.length, 1);
        assertEq(maxTally[0], 4);
    }

    function test_GetMultipleMaximalValueFromSubset() public {
        uint256[] memory testArray = new uint256[](10);
        testArray[1] = 5;
        testArray[2] = 9;
        testArray[3] = 15;
        testArray[4] = 20;
        testArray[5] = 33;
        testArray[6] = 15;
        testArray[7] = 20;
        testArray[8] = 15;
        testArray[9] = 2;

        uint256[] memory subset = new uint256[](6);
        subset[0] = 1;
        subset[1] = 2;
        subset[2] = 3;
        subset[3] = 4;
        subset[4] = 6;
        subset[5] = 7;

        uint256[] memory maxTally = testArray.maxSubset(subset);
        assertEq(maxTally.length, 2);
        assertEq(maxTally[0], 4);
        assertEq(maxTally[1], 7);
    }
}
