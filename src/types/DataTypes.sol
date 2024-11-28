// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ChallengeStarted } from "../commons/events.sol";
import { ChallengeCancelled } from "../commons/events.sol";

/// @title DataTypes
/// @dev Contains data structures and library functions

// Type declarations

/// @dev Settings for a partner
struct PartnerSettings {
    string soulboundTokenName;
    string soulboundTokenSymbol;
    address soulboundTokenAddress;
    string logoUrl;
    string logoSVG;
}

/// @dev Structure to hold challenges and their completions
struct ChallengesStruct {
    Challenge[] challenges;
    mapping(string => uint256) challengeIdToIndex;
    mapping(uint256 => ChallengeCompletion[]) challengeIdToChallengeCompletions;
}

/// @dev Structure representing a challenge
struct Challenge {
    uint256 id;
    address submitter;
    address soulboundToken;
    ChallengeTheme theme;
    string title;
    string description;
    string target; // product or service
    uint256 tokenRewardAmount; // number of tokens to be rewarded to every winner, fixed by the contract for now
    uint256 duration;
    uint256 startTime;
    uint256 maxWinners;
    ChallengeState state;
}

/// @dev Structure representing a challenge completion
struct ChallengeCompletion {
    uint256 id;
    address submitter;
    uint256 challengeId;
    bytes data;
    ChallengeCompletionStatus status;
    bool rewarded;
    uint256 evaluationTime;
}

/// @dev Enum for challenge themes
enum ChallengeTheme {
    FITNESS,
    NUTRITION
}

/// @dev Enum for challenge states
enum ChallengeState {
    PENDING,
    IN_PROGRESS,
    CANCELLED
}

/// @dev Enum for challenge completion statuses
enum ChallengeCompletionStatus {
    UNDEFINED,
    SUCCESS,
    FAILURE
}

/// @dev Data structure for wellness soulbound token
struct WellnessSoulboundTokenData {
    uint256 challengeCompletionId;
}

// Library

/// @dev Library for challenge operations
library ChallengeLibrary {
    /// @notice Starts a challenge
    /// @param challenge The challenge to start
    function startChallenge(Challenge storage challenge) internal {
        challenge.state = ChallengeState.IN_PROGRESS;
        challenge.startTime = block.timestamp;
        emit ChallengeStarted(challenge.id, challenge.startTime);
    }

    /// @notice Cancels a challenge
    /// @param challenge The challenge to cancel
    function cancelChallenge(Challenge storage challenge) internal {
        challenge.state = ChallengeState.CANCELLED;
        emit ChallengeCancelled(challenge.id, block.timestamp);
    }

    /// @notice Checks if a challenge is in progress
    /// @param challenge The challenge to check
    /// @return bool True if the challenge is in progress, false otherwise
    function isChallengeInProgress(Challenge memory challenge) internal view returns (bool) {
        // slither-disable-next-line block-timestamp
        return
            challenge.state == ChallengeState.IN_PROGRESS && challenge.startTime + challenge.duration > block.timestamp;
    }

    /// @notice Checks if a challenge is terminated
    /// @param challenge The challenge to check
    /// @return bool True if the challenge is terminated, false otherwise
    function isChallengeTerminated(Challenge memory challenge) internal view returns (bool) {
        // slither-disable-next-line block-timestamp
        return
            challenge.state == ChallengeState.IN_PROGRESS && challenge.startTime + challenge.duration < block.timestamp;
    }

    /// @notice Checks if a challenge is cancelled
    /// @param challenge The challenge to check
    /// @return bool True if the challenge is cancelled, false otherwise
    function isChallengeCancelled(Challenge memory challenge) internal pure returns (bool) {
        return challenge.state == ChallengeState.CANCELLED;
    }

    /// @notice Checks if a challenge is pending
    /// @param challenge The challenge to check
    /// @return bool True if the challenge is pending, false otherwise
    function isChallengePending(Challenge memory challenge) internal pure returns (bool) {
        return challenge.state == ChallengeState.PENDING;
    }
}
