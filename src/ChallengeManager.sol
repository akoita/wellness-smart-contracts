// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { IWellnessHome } from "./interfaces/IWellnessHome.sol";
import { IChallengeManager } from "./interfaces/IChallengeManager.sol";
import { IChallengeRewardStrategy } from "./interfaces/IChallengeRewardStrategy.sol";
import { IChallengeCompletionValidationStrategy } from "./interfaces/IChallengeCompletionValidationStrategy.sol";
import {
    ChallengeLibrary,
    Challenge,
    ChallengeCompletion,
    ChallengeState,
    ChallengeCompletionStatus,
    PartnerSettings
} from "./types/DataTypes.sol";
import { IterableMapping } from "./types/IterableMapping.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {
    ChallengeCompletionValidatorRoleRequired,
    NonExistingChallengeCompletion,
    NonExistingChallenge,
    ExpectedPendingChallenge,
    ExpectedStartedChallenge,
    ChallengeMaxWinnersReached,
    ChallengeCompletionAlreadySubmitted,
    ChallengeRewardStrategyRoleRequired,
    InvalidPartner,
    InvalidUser,
    InvalidInputChallenge,
    InvalidInputChallengeCompletion,
    InvalidChallengeSubmitter,
    ChallengeCompletionAlreadyEvaluated,
    AdminRoleRequired
} from "./commons/Errors.sol";

import { ChallengeSubmitted, ChallengeCompletionSubmitted, ChallengeCompletionEvaluated } from "./commons/events.sol";

/// @title ChallengeManager
/// @dev Manages challenges and their completions
contract ChallengeManager is AccessControlEnumerable, IChallengeManager {
    using EnumerableSet for EnumerableSet.UintSet;
    using ChallengeLibrary for Challenge;
    using IterableMapping for IterableMapping.ChallengesItMap;
    using IterableMapping for IterableMapping.ChallengeCompletionsItMap;

    // Type declarations
    bytes32 public constant CHALLENGE_COMPLETION_VALIDATOR_ROLE = keccak256("CHALLENGE_COMPLETION_VALIDATOR_ROLE");
    bytes32 public constant CHALLENGE_REWARD_STRATEGY_ROLE = keccak256("CHALLENGE_REWARD_STRATEGY_ROLE");

    // State variables

    // slither-disable-next-line immutable-states
    uint256 public challengeIdCounter;
    // slither-disable-next-line immutable-states
    uint256 public challengeCompletionIdCounter;
    // slither-disable-next-line immutable-states
    uint256 public minimumChallengeDuration;
    // slither-disable-next-line immutable-states
    uint256 public maximumChallengeDuration;
    IWellnessHome public wellnessHome;
    IChallengeRewardStrategy public challengeRewardStrategy;
    // slither-disable-next-line unused-state
    IterableMapping.ChallengesItMap internal _challenges;
    // slither-disable-next-line unused-state
    mapping(address partner => EnumerableSet.UintSet partnerChallengeIds) internal _partnersChallenges;
    // slither-disable-next-line unused-state
    IterableMapping.ChallengeCompletionsItMap internal _challengeCompletions;
    // slither-disable-next-line unused-state
    mapping(uint256 challengeId => EnumerableSet.UintSet challengeCompletionsIds) internal
        _challengeCompletionsByChallenge;
    // slither-disable-next-line unused-state
    mapping(uint256 challengeId => EnumerableSet.UintSet challengeCompletionsIds) internal
        _challengeCompletionsApprovedByChallenge;
    // slither-disable-next-line unused-state
    mapping(address user => EnumerableSet.UintSet userChallengeCompletionsIds) internal _usersChallengeCompletions;

    // Modifiers
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), AdminRoleRequired(msg.sender));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyChallengeCompletionValidator() {
        require(
            hasRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, msg.sender),
            ChallengeCompletionValidatorRoleRequired(msg.sender)
        );
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyChallengeRewardStrategy() {
        require(hasRole(CHALLENGE_REWARD_STRATEGY_ROLE, msg.sender), ChallengeRewardStrategyRoleRequired(msg.sender));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyPartner() {
        require(wellnessHome.isPartner(msg.sender), InvalidPartner(msg.sender));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyChallengeSubmitter(address submitter, uint256 challengeId) {
        require(
            address(0) != submitter && _challenges.get(challengeId).submitter == submitter,
            InvalidChallengeSubmitter(challengeId, submitter)
        );
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyUser(address user) {
        require(wellnessHome.isUser(user), InvalidUser(user));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyPendingChallenge(uint256 challengeId) {
        Challenge storage challenge = _challenges.get(challengeId);
        require(challenge.isChallengePending(), ExpectedPendingChallenge(challengeId, challenge.state));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyInProgressChallenge(uint256 challengeId) {
        require(_challenges.get(challengeId).isChallengeInProgress(), ExpectedStartedChallenge(challengeId));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyExistingChallenge(uint256 challengeId) {
        require(_challenges.contains(challengeId), NonExistingChallenge(challengeId));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyExistingChallengeCompletion(uint256 challengeCompletionId) {
        require(challengeCompletionExists(challengeCompletionId), NonExistingChallengeCompletion(challengeCompletionId));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyMaxWinnersNotReached(uint256 challengeId) {
        uint256 maxWinners = _challenges.get(challengeId).maxWinners;
        require(
            _challengeCompletionsApprovedByChallenge[challengeId].length() < maxWinners,
            ChallengeMaxWinnersReached(challengeId, maxWinners)
        );
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotYetSubmittedChallengeCompletion(uint256 challengeId, address user) {
        require(
            !_usersChallengeCompletions[user].contains(challengeId),
            ChallengeCompletionAlreadySubmitted(challengeId, user)
        );
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotYetEvaluatedChallengeCompletion(uint256 challengeCompletionId) {
        ChallengeCompletion storage completion = _challengeCompletions.get(challengeCompletionId);
        require(
            completion.status == ChallengeCompletionStatus.UNDEFINED,
            ChallengeCompletionAlreadyEvaluated(challengeCompletionId)
        );
        _;
    }

    // Constructor
    constructor(address initialOwner, address wellnessHomeAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        challengeIdCounter = 1;
        challengeCompletionIdCounter = 1;
        minimumChallengeDuration = 1 days;
        maximumChallengeDuration = 10 days;
        wellnessHome = IWellnessHome(wellnessHomeAddress);
    }

    // External functions
    function setWellnessHome(address wellnessHomeAddress) external onlyAdmin {
        wellnessHome = IWellnessHome(wellnessHomeAddress);
    }

    function setChallengeRewardStrategy(address challengeRewardStrategyAddress) external onlyAdmin {
        challengeRewardStrategy = IChallengeRewardStrategy(challengeRewardStrategyAddress);
    }

    function grantDefaultAdminRole(address defaultAdmin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function revokeDefaultAdminRole(address defaultAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function hasAdminRole(address admin) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function grantChallengeCompletionValidatorRole(
        IChallengeCompletionValidationStrategy challengeCompletionValidator
    )
        external
        onlyAdmin
    {
        _grantRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, address(challengeCompletionValidator));
    }

    function revokeChallengeCompletionValidatorRole(
        IChallengeCompletionValidationStrategy challengeCompletionValidator
    )
        external
        onlyAdmin
    {
        _revokeRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, address(challengeCompletionValidator));
    }

    function hasChallengeCompletionValidatorRole(
        IChallengeCompletionValidationStrategy challengeCompletionValidator
    )
        external
        view
        returns (bool)
    {
        return hasRole(CHALLENGE_COMPLETION_VALIDATOR_ROLE, address(challengeCompletionValidator));
    }

    function grantChallengeRewardStrategyRole(IChallengeRewardStrategy challengeRewardStrategy_) external onlyAdmin {
        _grantRole(CHALLENGE_REWARD_STRATEGY_ROLE, address(challengeRewardStrategy_));
    }

    function revokeChallengeRewardStrategyRole(IChallengeRewardStrategy challengeRewardStrategy_) external onlyAdmin {
        _revokeRole(CHALLENGE_REWARD_STRATEGY_ROLE, address(challengeRewardStrategy_));
    }

    function hasChallengeRewardStrategyRole(address challengeRewardStrategy_) external view returns (bool) {
        return hasRole(CHALLENGE_REWARD_STRATEGY_ROLE, challengeRewardStrategy_);
    }

    function submitChallenge(Challenge memory challenge) external onlyPartner {
        require(bytes(challenge.title).length > 0, InvalidInputChallenge("Challenge title is required"));
        require(bytes(challenge.description).length > 0, InvalidInputChallenge("Challenge description is required"));
        require(
            bytes(challenge.target).length > 0,
            InvalidInputChallenge("Challenge target (product or service) is required")
        );
        require(challenge.maxWinners > 0, InvalidInputChallenge("Challenge max winners must be greater than 0"));
        require(
            challenge.duration >= minimumChallengeDuration,
            InvalidInputChallenge("Challenge duration less than minimum")
        );
        require(
            challenge.duration <= maximumChallengeDuration,
            InvalidInputChallenge("Challenge duration greater than maximum")
        );

        challenge.id = challengeIdCounter;
        challengeIdCounter++;
        challenge.submitter = msg.sender;
        challenge.state = ChallengeState.PENDING;
        challenge.tokenRewardAmount = 1;
        PartnerSettings memory partnerSettings = wellnessHome.getPartnerSettings(msg.sender);
        challenge.soulboundToken = partnerSettings.soulboundTokenAddress;
        _challenges.set(challenge.id, challenge);
        _partnersChallenges[msg.sender].add(challenge.id);
        emit ChallengeSubmitted(challenge.id, msg.sender, challenge.theme, challenge);
    }

    function startChallenge(
        uint256 challengeId
    )
        external
        onlyExistingChallenge(challengeId)
        onlyPendingChallenge(challengeId)
        onlyChallengeSubmitter(msg.sender, challengeId)
    {
        _challenges.get(challengeId).startChallenge();
    }

    function cancelChallenge(
        uint256 challengeId
    )
        external
        onlyExistingChallenge(challengeId)
        onlyPendingChallenge(challengeId)
        onlyChallengeSubmitter(msg.sender, challengeId)
    {
        _challenges.get(challengeId).cancelChallenge();
    }

    function submitChallengeCompletion(
        ChallengeCompletion memory completion
    )
        external
        onlyUser(msg.sender)
        onlyExistingChallenge(completion.challengeId)
        onlyInProgressChallenge(completion.challengeId)
        onlyMaxWinnersNotReached(completion.challengeId)
        onlyNotYetSubmittedChallengeCompletion(completion.challengeId, msg.sender)
    {
        require(
            bytes(completion.data).length > 0, InvalidInputChallengeCompletion("Challenge completion data is required")
        );
        completion.id = challengeCompletionIdCounter;
        challengeCompletionIdCounter++;
        completion.submitter = msg.sender;
        completion.status = ChallengeCompletionStatus.UNDEFINED;
        completion.rewarded = false;
        _challengeCompletions.set(completion.id, completion);
        _challengeCompletionsByChallenge[completion.challengeId].add(completion.id);
        _usersChallengeCompletions[msg.sender].add(completion.id);
        emit ChallengeCompletionSubmitted(completion.id, completion.challengeId, msg.sender, completion);
    }

    /// @inheritdoc IChallengeManager
    function evaluateChallengeCompletion(
        uint256 challengeCompletionId,
        bool approved
    )
        external
        onlyChallengeCompletionValidator
        onlyExistingChallengeCompletion(challengeCompletionId)
        onlyNotYetEvaluatedChallengeCompletion(challengeCompletionId)
    {
        ChallengeCompletion storage completion = _challengeCompletions.get(challengeCompletionId);
        if (
            _challengeCompletionsApprovedByChallenge[completion.challengeId].length()
                >= _challenges.get(completion.challengeId).maxWinners
        ) {
            revert ChallengeMaxWinnersReached(
                completion.challengeId, _challenges.get(completion.challengeId).maxWinners
            );
        }
        completion.status = approved ? ChallengeCompletionStatus.SUCCESS : ChallengeCompletionStatus.FAILURE;
        completion.evaluationTime = block.timestamp;
        if (approved) {
            _challengeCompletionsApprovedByChallenge[completion.challengeId].add(challengeCompletionId);
        }
        emit ChallengeCompletionEvaluated(
            challengeCompletionId, completion.challengeId, completion.submitter, completion
        );
    }

    /// @inheritdoc IChallengeManager
    function updateRewardStateAsClaimed(
        uint256 challengeCompletionId
    )
        external
        onlyChallengeRewardStrategy
        onlyExistingChallengeCompletion(challengeCompletionId)
    {
        _challengeCompletions.get(challengeCompletionId).rewarded = true;
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
        ChallengeCompletion storage completion = _challengeCompletions.get(challengeCompletionId);
        return completion.status == ChallengeCompletionStatus.SUCCESS && !completion.rewarded;
    }

    function isChallengeCompletionApproved(
        uint256 challengeCompletionId
    )
        external
        view
        onlyExistingChallengeCompletion(challengeCompletionId)
        returns (bool)
    {
        return _challengeCompletions.get(challengeCompletionId).status == ChallengeCompletionStatus.SUCCESS;
    }

    function challengeCompletionExists(uint256 challengeCompletionId) public view returns (bool) {
        return challengeCompletionId != 0 && _challengeCompletions.contains(challengeCompletionId);
    }

    function getChallengeCompletion(
        uint256 challengeCompletionId
    )
        external
        view
        onlyExistingChallengeCompletion(challengeCompletionId)
        returns (ChallengeCompletion memory)
    {
        return _challengeCompletions.get(challengeCompletionId);
    }

    function getChallengeByCompletion(
        uint256 challengeCompletionId
    )
        external
        view
        onlyExistingChallengeCompletion(challengeCompletionId)
        returns (Challenge memory)
    {
        return _challenges.get(_challengeCompletions.get(challengeCompletionId).challengeId);
    }

    function challengeExists(uint256 challengeId) public view returns (bool) {
        return challengeId != 0 && _challenges.contains(challengeId);
    }

    function getChallenge(
        uint256 challengeId
    )
        external
        view
        onlyExistingChallenge(challengeId)
        returns (Challenge memory)
    {
        return _challenges.get(challengeId);
    }

    function getChallengeCompletionsByChallenge(
        uint256 challengeId
    )
        external
        view
        onlyExistingChallenge(challengeId)
        returns (uint256[] memory challengeCompletionIds)
    {
        return _challengeCompletionsByChallenge[challengeId].values();
    }

    function getApprovedChallengeCompletionsByChallenge(
        uint256 challengeId
    )
        external
        view
        onlyExistingChallenge(challengeId)
        returns (uint256[] memory challengeCompletionIds)
    {
        return _challengeCompletionsApprovedByChallenge[challengeId].values();
    }

    function getUserChallengeCompletions(
        address user
    )
        external
        view
        onlyUser(user)
        returns (uint256[] memory challengeCompletionIds)
    {
        return _usersChallengeCompletions[user].values();
    }
}
