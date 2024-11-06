// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IChallengeRewardStrategy {
    function claimReward(uint256 challengeId) external;
}
