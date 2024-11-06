// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Challenge, ChallengeCompletion } from "../types/DataTypes.sol";

interface IChallengeManager {
    function submitChallenge(Challenge memory challenge) external;

    function startChallenge(uint256 challengeId) external;
    function cancelChallenge(uint256 challengeId) external;

    function submitChallengeCompletion(ChallengeCompletion memory completion) external;

    function approoveChallengeCompletion(uint256 challengeCompletionId, bool approved) external;

    function isChallengeCompletionApproved(uint256 challengeCompletionId) external view returns (bool);

    function hasPendingReward(uint256 challengeCompletionId) external view returns (bool);

    function updateRewardStateAsClaimed(uint256 challengeCompletionId) external;

    function challengeCompletionExists(uint256 challengeCompletionId) external view returns (bool);
}
