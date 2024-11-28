// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ChallengeTheme } from "../types/DataTypes.sol";
import { Challenge } from "../types/DataTypes.sol";
import { ChallengeCompletion } from "../types/DataTypes.sol";

event ChallengeSubmitted(
    uint256 indexed challengeId, address indexed submitter, ChallengeTheme indexed theme, Challenge challenge
);

event ChallengeCompletionSubmitted(
    uint256 indexed challengeCompletionId,
    uint256 indexed challengeId,
    address indexed submitter,
    ChallengeCompletion challengeCompletion
);

event ChallengeStarted(uint256 indexed challengeId, uint256 indexed startTime);

event ChallengeCancelled(uint256 indexed challengeId, uint256 indexed cancelTime);

event ChallengeCompletionEvaluated(
    uint256 indexed challengeCompletionId,
    uint256 indexed challengeId,
    address indexed submitter,
    ChallengeCompletion challengeCompletion
);

event Minted(uint256 indexed tokenId, address indexed to, uint256 indexed challengeCompletionId);
