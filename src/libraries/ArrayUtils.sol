pragma solidity ^0.8.13;

library ArrayUtils {

    /// @notice Sum the values in a uint256 array
    /// @param self The array whose elements are being summed
    /// @return total The sum of all the elements
    function sum(uint256[] memory self) internal pure returns (uint256 total) {
        total = 0;
        for (uint256 i = 0; i < self.length; i++) {
            total += self[i];
        }
        return total;
    }

    /// @notice Check if each element in an array is unique
    /// @dev This function only works on calldata arrays
    /// @param self The array whose elements you want to check
    /// @return True if all the elements are unique, otherwise false
    function unique(uint256[] calldata self) internal pure returns (bool) {
        for (uint256 i = 0; i < self.length - 1; i++) {
            uint256 proposal = self[i];
            for (uint256 j = i + 1; j < self.length; j++) {
                if (proposal == self[j]) {
                    return false;
                }
            }
        }
        return true;
    }


}
