
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "../src/libraries/ArrayUtils.sol";


contract TestArrayUtils is Test {
    using ArrayUtils for uint256[];

    function memoryToCallData(uint256[] calldata array) external pure returns (uint256[] calldata) {
        return array;
    }
    
    function test_SumArray() public {
        uint256[] memory testArray = new uint256[](15);

        testArray[0] = 20;
        testArray[1] = 33;
        testArray[2] = 3121349;
        testArray[3] = 312134956655547;
        testArray[4] = 56655547;
        testArray[5] = 4668417;
        testArray[6] = 367443554668417;
        testArray[7] = 84007127;
        testArray[8] = 575654081763;
        testArray[9] = 856456779930;
        testArray[10] = 71253940608;
        testArray[11] = 303144852494;
        testArray[12] = 77454897142;
        testArray[13] = 968847206994;
        testArray[14] = 34245808923346684174668417;

        uint256 total = testArray.sum();
        assertEq(total, 20 +
                        33 +
                        3121349 +
                        312134956655547 +
                        56655547 +
                        4668417 +
                        367443554668417 +
                        84007127 +
                        575654081763 +
                        856456779930 +
                        71253940608 +
                        303144852494 +
                        77454897142 +
                        968847206994 +
                        34245808923346684174668417);
    }

}
