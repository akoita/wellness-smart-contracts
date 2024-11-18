// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title IChallengeCompletionValidationStrategy
 * @dev Interface for validating if a challenge completion has met the requirements.
 */
interface IChallengeCompletionValidationStrategy {
    /**
     * @notice Checks if the challenge completion has met the requirements.
     * @param challengeCompletionId The ID of the challenge completion to check.
     * @return bool True if the challenge completion has met the requirements, false otherwise.
     */
    function hasChallengeCompletionMetRequirements(uint256 challengeCompletionId) external view returns (bool);
}
