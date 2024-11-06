// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

struct ChallengesStruct {
    Challenge[] challenges;
    mapping(string => uint256) challengeIdToIndex;
    mapping(uint256 => ChallengeCompletion[]) challengeIdToChallengeCompletions;
}

struct Challenge {
    uint256 id;
    address submitter;
    ChallengeTheme theme;
    string title;
    string description;
    string target; // product or service
    uint256 tokenRewardAmount;
    uint256 startTime;
    uint256 duration;
    uint256 maxWinners;
    ChallengeState state;
}

struct ChallengeCompletion {
    uint256 id;
    address submitter;
    uint256 challengeId;
    bytes data;
    ChallengeCompletionStatus status;
    bool rewarded;
}

enum ChallengeTheme {
    FITNESS,
    NUTRITION
}

enum ChallengeState {
    PENDING,
    IN_PROGRESS,
    CANCELLED
}

enum ChallengeCompletionStatus {
    UNDEFINED,
    SUCCESS,
    FAILURE
}

library ChallengeLibrary {
    function key(Challenge memory challenge) internal pure returns (uint256) {
        // TODO: check if this is correct
        return uint256(keccak256(abi.encode(challenge.id)));
    }

    function startChallenge(Challenge storage challenge) internal {
        challenge.state = ChallengeState.IN_PROGRESS;
        challenge.startTime = block.timestamp;
    }

    function cancelChallenge(Challenge storage challenge) internal {
        challenge.state = ChallengeState.CANCELLED;
    }

    function isChallengeInProgress(Challenge memory challenge) internal view returns (bool) {
        return
            challenge.state == ChallengeState.IN_PROGRESS && challenge.startTime + challenge.duration > block.timestamp;
    }

    function isChallengeTerminated(Challenge memory challenge) internal view returns (bool) {
        return
            challenge.state == ChallengeState.IN_PROGRESS && challenge.startTime + challenge.duration < block.timestamp;
    }

    function isChallengeCancelled(Challenge memory challenge) internal pure returns (bool) {
        return challenge.state == ChallengeState.CANCELLED;
    }

    function isChallengePending(Challenge memory challenge) internal pure returns (bool) {
        return challenge.state == ChallengeState.PENDING;
    }
}

library ChallengeCompletionLibrary {
    function key(ChallengeCompletion memory completion) internal pure returns (uint256) {
        // TODO: check if this is correct
        return uint256(keccak256(abi.encode(completion.id)));
    }
}
