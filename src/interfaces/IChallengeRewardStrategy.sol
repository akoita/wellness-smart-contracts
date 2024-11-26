// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title IChallengeRewardStrategy
 * @dev Interface for claiming rewards for challenges.
 */
interface IChallengeRewardStrategy {
    /**
     * @notice Claims the reward for a specific challenge.
     * @param challengeId The ID of the challenge for which to claim the reward.
     */
    function claimReward(uint256 challengeId) external;
}
