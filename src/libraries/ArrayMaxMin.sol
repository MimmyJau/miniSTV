pragma solidity ^0.8.13;

library ArrayMaxMin {

    /// @notice Get list of indices with the maximal value in an array. Can filter to only compare a subset of indices.
    /// @param self An array of numerical values that may contain duplicates
    /// @param subset An array of the subset of indices in "self" we want to compare against
    /// @return maxIndices List of indices with the highest value
    function maxSubset(
        uint256[] memory self,
        uint256[] memory subset 
    ) internal pure returns (uint256[] memory maxIndices) {

        // won't add an error message since this should never occur
        require(self.length > 0);

        // track indices(s) with the highest value
        uint256[] memory maxIndices_ = new uint256[](subset.length);
        maxIndices_[0] = subset[0];
        uint256 maxValue = self[subset[0]];

        // another index for tracking number of tied indices
        uint256 j = 1;

        for (uint256 i = 1; i < subset.length; i++) {
            // store in named variables for clarity
            uint256 index = subset[i];
            uint256 value = self[index];
            // if there's a tie, keep track of all tied indices
            if (value == maxValue) {
                maxIndices_[j++] = index;
            } else if (value > maxValue) {
                // if we find index with higher value, clear history of previous tied indices
                while (j > 0) {
                    maxIndices_[j--] = 0;
                }
                j = 1;
                maxValue = value;
                maxIndices_[0] = index;
            }
        }

        // remove unused elements in array before returning
        maxIndices = new uint256[](j);
        for (uint256 i = 0; i < j; i++) {
            maxIndices[i] = maxIndices_[i];
        }

        return maxIndices;
    }


    /// @notice Finds proposal with most votes in an array. Returns an array in case there are ties.
    /// @dev Arrays of proposals start at index 1. Index 0 is always empty.
    /// @param self An array of numerical values that may contain duplicates
    /// @return maxIndices List of indices with the highest value
    function maxTally(uint256[] memory self) internal pure returns (uint256[] memory maxIndices) {

        // won't add an error message since this should never occur
        require(self.length > 0);

        uint256[] memory proposalIndices = new uint256[](self.length - 1);
        uint256 j = 0;
        for (uint i = 1; i < self.length; i++) {
            proposalIndices[j++] = i;
        }

        maxIndices = maxSubset(self, proposalIndices);
        
        return maxIndices;
    }


    /// @notice Get list of indices with the minimal value in an array. Can filter to only compare a subset of indices.
    /// @param self An array of numerical values that may contain duplicates
    /// @param subset An array of the subset of indices in "self" we want to compare against
    /// @return minIndices List of indices with the lowest value
    function minSubset(
        uint256[] memory self,
        uint256[] memory subset 
    ) internal pure returns (uint256[] memory minIndices) {

        // won't add an error message since this should never occur
        require(self.length > 0);

        // track indices(s) with the highest value
        uint256[] memory minIndices_ = new uint256[](subset.length);
        minIndices_[0] = subset[0];
        uint256 minValue = self[subset[0]];

        // another index for tracking number of tied indices
        uint256 j = 1;

        for (uint256 i = 1; i < subset.length; i++) {
            // store in named variables for clarity
            uint256 index = subset[i];
            uint256 value = self[index];
            // if there's a tie, keep track of all tied indices
            if (value == minValue) {
                minIndices_[j++] = index;
            } else if (value < minValue) {
                // if we find index with lower value, clear history of previous tied indices
                while (j > 0) {
                    minIndices_[j--] = 0;
                }
                j = 1;
                minValue = value;
                minIndices_[0] = index;
            }
        }

        // remove unused elements in array before returning
        minIndices = new uint256[](j);
        for (uint256 i = 0; i < j; i++) {
            minIndices[i] = minIndices_[i];
        }

        return minIndices;
    }

    /// @notice Finds proposal with least votes in an array. Returns an array in case there are ties.
    /// @dev Arrays of proposals start at index 1. Index 0 is always empty.
    /// @param self An array of numerical values that may contain duplicates
    /// @return minIndices List of indices with the lowest value
    function minTally(uint256[] memory self) internal pure returns (uint256[] memory minIndices) {

        // won't add an error message since this should never occur
        require(self.length > 0);

        uint256[] memory proposalIndices = new uint256[](self.length - 1);
        uint256 j = 0;
        for (uint i = 1; i < self.length; i++) {
            proposalIndices[j++] = i;
        }

        minIndices = minSubset(self, proposalIndices);
        
        return minIndices;
    }
}
