// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Challenge, ChallengeCompletion } from "../types/DataTypes.sol";

/**
 * @title IChallengeManager
 * @dev Interface for managing challenges and their completions.
 */
interface IChallengeManager {
    /**
     * @notice Submits a new challenge.
     * @param challenge The challenge to be submitted.
     */
    function submitChallenge(Challenge memory challenge) external;

    /**
     * @notice Starts a challenge.
     * @param challengeId The ID of the challenge to start.
     */
    function startChallenge(uint256 challengeId) external;

    /**
     * @notice Cancels a challenge.
     * @param challengeId The ID of the challenge to cancel.
     */
    function cancelChallenge(uint256 challengeId) external;

    /**
     * @notice Submits a challenge completion.
     * @param completion The challenge completion to be submitted.
     */
    function submitChallengeCompletion(ChallengeCompletion memory completion) external;

    /**
     * @notice Evaluates a challenge completion.
     * @param challengeCompletionId The ID of the challenge completion to evaluate.
     * @param approved Whether the challenge completion is approved or not.
     */
    function evaluateChallengeCompletion(uint256 challengeCompletionId, bool approved) external;

    /**
     * @notice Checks if a challenge completion is approved.
     * @param challengeCompletionId The ID of the challenge completion to check.
     * @return bool True if the challenge completion is approved, false otherwise.
     */
    function isChallengeCompletionApproved(uint256 challengeCompletionId) external view returns (bool);

    /**
     * @notice Checks if a challenge completion has a pending reward.
     * @param challengeCompletionId The ID of the challenge completion to check.
     * @return bool True if the challenge completion has a pending reward, false otherwise.
     */
    function hasPendingReward(uint256 challengeCompletionId) external view returns (bool);

    /**
     * @notice Updates the reward state of a challenge completion as claimed.
     * @param challengeCompletionId The ID of the challenge completion to update.
     */
    function updateRewardStateAsClaimed(uint256 challengeCompletionId) external;

    /**
     * @notice Checks if a challenge completion exists.
     * @param challengeCompletionId The ID of the challenge completion to check.
     * @return bool True if the challenge completion exists, false otherwise.
     */
    function challengeCompletionExists(uint256 challengeCompletionId) external view returns (bool);

    /**
     * @notice Gets a challenge completion by its ID.
     * @param challengeCompletionId The ID of the challenge completion to get.
     * @return ChallengeCompletion The challenge completion.
     */
    function getChallengeCompletion(uint256 challengeCompletionId) external view returns (ChallengeCompletion memory);

    /**
     * @notice Gets a challenge by its completion ID.
     * @param challengeCompletionId The ID of the challenge completion.
     * @return Challenge The challenge.
     */
    function getChallengeByCompletion(uint256 challengeCompletionId) external view returns (Challenge memory);

    /**
     * @notice Gets a challenge by its ID.
     * @param challengeId The ID of the challenge to get.
     * @return Challenge The challenge.
     */
    function getChallenge(uint256 challengeId) external view returns (Challenge memory);
}
