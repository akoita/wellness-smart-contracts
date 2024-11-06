// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IWellnessHome } from "./interfaces/IWellnessHome.sol";
import { IChallengeCompletionValidationStrategy } from "./interfaces/IChallengeCompletionValidationStrategy.sol";
import { IChallengeManager } from "./interfaces/IChallengeManager.sol";
import { IChallengeRewardStrategy } from "./interfaces/IChallengeRewardStrategy.sol";
import { ChallengeLibrary } from "./types/DataTypes.sol";
import { IterableMapping } from "./types/IterableMapping.sol";
import { Challenge, ChallengeCompletion } from "./types/DataTypes.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ChallengeState } from "./types/DataTypes.sol";
import { ChallengeCompletionStatus } from "./types/DataTypes.sol";
import { ChallengeCompletionValidatorRoleRequired, NonExistingChallengeCompletion } from "./commons/Errors.sol";
import { NonExistingChallenge } from "./commons/Errors.sol";
import { ExpectedPendingChallenge, ExpectedStartedChallenge, ChallengeMaxWinnersReached } from "./commons/Errors.sol";
import { ChallengeCompletionLibrary } from "./types/DataTypes.sol";
import { ChallengeCompletionAlreadySubmitted } from "./commons/Errors.sol";
import { ChallengeRewardStrategyRoleRequired } from "./commons/Errors.sol";

import {
    InvalidPartner,
    InvalidUser,
    UserOperationNotAllowedForPartner,
    UserOperationNotAllowedForOwner
} from "./commons/Errors.sol";

contract ChallengeManager is AccessControl, IChallengeManager {
    using EnumerableSet for EnumerableSet.UintSet;
    using ChallengeLibrary for Challenge;
    using ChallengeCompletionLibrary for ChallengeCompletion;
    using IterableMapping for IterableMapping.ChallengesItMap;
    using IterableMapping for IterableMapping.ChallengeCompletionsItMap;

    event ChallengeSubmitted(string challengeId, address indexed partner);
    event ChallengeCompletionSubmitted(string challengeId, address indexed partner);

    bytes32 public constant CHALLENGE_COMPLETION_VALIDATOR_ROLE = keccak256("CHALLENGE_COMPLETION_VALIDATOR_ROLE");
    bytes32 public constant CHALLENGE_REWARD_STRATEGY_ROLE = keccak256("CHALLENGE_REWARD_STRATEGY_ROLE");

    // State variables
    IWellnessHome public wellnessHome;
    IChallengeRewardStrategy public challengeRewardStrategy;

    IterableMapping.ChallengesItMap internal challenges;
    IterableMapping.ChallengeCompletionsItMap internal challengeCompletions;
    mapping(uint256 challengeId => EnumerableSet.UintSet challengeCompletionIds) internal
        challengeCompletionsByChallenge;
    mapping(address user => EnumerableSet.UintSet challengeCompletionIds) internal usersChallengeCompletions;
    mapping(uint256 challengeId => EnumerableSet.UintSet challengeCompletionIds) internal challengeCompletionsApproved;

    // Modifiers

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a default admin");
        _;
    }

    modifier onlyChallengeCompletionValidator() {
        require(
            hasRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, msg.sender),
            ChallengeCompletionValidatorRoleRequired(msg.sender)
        );
        _;
    }

    modifier onlyChallengeRewardStrategy() {
        require(hasRole(CHALLENGE_REWARD_STRATEGY_ROLE, msg.sender), ChallengeRewardStrategyRoleRequired(msg.sender));
        _;
    }

    modifier onlyPartner() {
        require(wellnessHome.isPartner(msg.sender), InvalidPartner(msg.sender));
        _;
    }

    modifier onlyUser() {
        require(wellnessHome.isUser(msg.sender), InvalidUser(msg.sender));
        _;
    }

    modifier onlyPendingChallenge(uint256 challengeId) {
        require(challenges.contains(challengeId), NonExistingChallenge(challengeId));
        require(challenges.get(challengeId).isChallengePending(), ExpectedPendingChallenge(challengeId));
        _;
    }

    modifier onlyInProgressChallenge(uint256 challengeId) {
        require(challenges.contains(challengeId), NonExistingChallenge(challengeId));
        require(challenges.get(challengeId).isChallengeInProgress(), ExpectedStartedChallenge(challengeId));
        require(
            challengeCompletionsByChallenge[challengeId].length() < challenges.get(challengeId).maxWinners,
            ChallengeMaxWinnersReached(challengeId)
        );

        _;
    }

    modifier onlyExistingChallengeCompletion(uint256 challengeCompletionId) {
        require(challengeCompletionExists(challengeCompletionId), NonExistingChallengeCompletion(challengeCompletionId));
        _;
    }

    modifier onlyNotYetSubmittedChallengeCompletion(uint256 challengeId, address user) {
        require(challenges.contains(challengeId), NonExistingChallenge(challengeId));
        require(
            !usersChallengeCompletions[user].contains(challengeId),
            ChallengeCompletionAlreadySubmitted(challengeId, user)
        );
        _;
    }

    constructor(address initialOwner, address wellnessHomeAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        wellnessHome = IWellnessHome(wellnessHomeAddress);
    }

    function setWellnessHome(address wellnessHomeAddress) external onlyAdmin {
        wellnessHome = IWellnessHome(wellnessHomeAddress);
    }

    function grantDefaultAdminRole(address defaultAdmin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function revokeDefaultAdminRole(address defaultAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function grantChallengeCompletionValidatorRole(address challengeCompletionValidator) external onlyAdmin {
        _grantRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, challengeCompletionValidator);
    }

    function revokeChallengeCompletionValidatorRole(address challengeCompletionValidator) external onlyAdmin {
        _revokeRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, challengeCompletionValidator);
    }

    function grantChallengeRewardStrategyRole(address challengeRewardStrategy_) external onlyAdmin {
        _grantRole(CHALLENGE_REWARD_STRATEGY_ROLE, challengeRewardStrategy_);
    }

    function revokeChallengeRewardStrategyRole(address challengeRewardStrategy_) external onlyAdmin {
        _revokeRole(CHALLENGE_REWARD_STRATEGY_ROLE, challengeRewardStrategy_);
    }

    /// @inheritdoc IChallengeManager
    function updateRewardStateAsClaimed(
        uint256 challengeCompletionId
    )
        external
        onlyChallengeRewardStrategy
        onlyExistingChallengeCompletion(challengeCompletionId)
    {
        challengeCompletions.get(challengeCompletionId).rewarded = true;
    }

    /// @inheritdoc IChallengeManager
    function hasPendingReward(
        uint256 challengeCompletionId
    )
        external
        view
        onlyExistingChallengeCompletion(challengeCompletionId)
        returns (bool)
    {
        ChallengeCompletion storage completion = challengeCompletions.get(challengeCompletionId);
        return !completion.rewarded;
    }

    /// @inheritdoc IChallengeManager
    function approoveChallengeCompletion(
        uint256 challengeCompletionId,
        bool approved
    )
        external
        onlyChallengeCompletionValidator
        onlyInProgressChallenge(challengeCompletionId)
        onlyExistingChallengeCompletion(challengeCompletionId)
    {
        ChallengeCompletion storage completion = challengeCompletions.get(challengeCompletionId);
        completion.status = approved ? ChallengeCompletionStatus.SUCCESS : ChallengeCompletionStatus.FAILURE;
        challengeCompletions.set(challengeCompletionId, completion);
        challengeCompletionsApproved[completion.challengeId].add(challengeCompletionId);
    }

    function submitChallenge(Challenge memory challenge) external onlyPartner {
        challenge.submitter = msg.sender;
        challenge.state = ChallengeState.PENDING;
        challenge.id = challenge.key();
        challenges.set(challenge.id, challenge);
    }

    function startChallenge(uint256 challengeId) external onlyPartner onlyPendingChallenge(challengeId) {
        challenges.get(challengeId).startChallenge();
    }

    function cancelChallenge(uint256 challengeId) external onlyPartner onlyPendingChallenge(challengeId) {
        challenges.get(challengeId).cancelChallenge();
    }

    function submitChallengeCompletion(
        ChallengeCompletion memory completion
    )
        external
        onlyUser
        onlyNotYetSubmittedChallengeCompletion(completion.challengeId, msg.sender)
        onlyExistingChallengeCompletion(completion.id)
        onlyInProgressChallenge(completion.challengeId)
    {
        completion.submitter = msg.sender;
        completion.id = completion.key();
        challengeCompletions.set(completion.id, completion);
        challengeCompletionsByChallenge[completion.challengeId].add(completion.id);
        usersChallengeCompletions[msg.sender].add(completion.id);
    }

    function isChallengeCompletionApproved(
        uint256 challengeCompletionId
    )
        external
        view
        onlyExistingChallengeCompletion(challengeCompletionId)
        returns (bool)
    {
        return challengeCompletions.get(challengeCompletionId).status == ChallengeCompletionStatus.SUCCESS;
    }

    function challengeCompletionExists(uint256 challengeCompletionId) public view returns (bool) {
        return challengeCompletionId != 0 && challengeCompletions.contains(challengeCompletionId);
    }
}
