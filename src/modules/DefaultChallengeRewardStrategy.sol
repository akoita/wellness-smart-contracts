// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Import statements
import { IChallengeRewardStrategy } from "../interfaces/IChallengeRewardStrategy.sol";
import { IChallengeManager } from "../interfaces/IChallengeManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWellnessSoulboundToken } from "../interfaces/IWellnessSoulboundToken.sol";
import {
    NoPendingReward,
    InvalidTokenRewardAmount,
    NonExistingChallengeCompletion,
    InvalidChallengeCompletionSubmitter
} from "../commons/Errors.sol";
import { Challenge } from "../types/DataTypes.sol";

/// @title DefaultChallengeRewardStrategy
/// @dev Implements the IChallengeRewardStrategy interface for claiming rewards
contract DefaultChallengeRewardStrategy is Ownable, IChallengeRewardStrategy {
    // State variables
    IChallengeManager public challengeManager;
    uint256 public tokenRewardAmount;

    // Modifiers
    /// @dev Modifier to check if a reward is pending for a given challenge completion ID
    /// @param challengeCompletionId The ID of the challenge completion
    // slither-disable-next-line incorrect-modifier
    modifier onlyExistingReward(uint256 challengeCompletionId) {
        require(challengeManager.hasPendingReward(challengeCompletionId), NoPendingReward(challengeCompletionId));
        _;
    }

    /// @dev Modifier to ensure the reward amount is valid
    /// @param tokenRewardAmount_ The reward amount to validate
    // slither-disable-next-line incorrect-modifier
    modifier onlyValidRewardAmount(uint256 tokenRewardAmount_) {
        require(tokenRewardAmount_ > 0 && tokenRewardAmount_ <= 10, InvalidTokenRewardAmount(tokenRewardAmount_));
        _;
    }

    /// @dev Modifier to check if a challenge completion exists
    /// @param challengeCompletionId The ID of the challenge completion
    // slither-disable-next-line incorrect-modifier
    modifier onlyExistingChallengeCompletion(uint256 challengeCompletionId) {
        require(
            challengeManager.challengeCompletionExists(challengeCompletionId),
            NonExistingChallengeCompletion(challengeCompletionId)
        );
        _;
    }

    /// @dev Modifier to ensure the caller is the submitter of the challenge completion
    /// @param challengeCompletionId The ID of the challenge completion
    /// @param submitter The address of the submitter
    // slither-disable-next-line incorrect-modifier
    modifier onlyChallengeCompletionSubmitter(uint256 challengeCompletionId, address submitter) {
        require(
            challengeManager.getChallengeCompletion(challengeCompletionId).submitter == submitter,
            InvalidChallengeCompletionSubmitter(challengeCompletionId, submitter)
        );
        _;
    }

    // Constructor
    /// @notice Constructor to initialize the contract with the owner
    /// @param owner The address of the contract owner
    constructor(address owner) Ownable(owner) {
        tokenRewardAmount = 1;
    }

    // External functions
    /// @notice Sets the challenge manager contract
    /// @param challengeManager_ The address of the challenge manager contract
    function setChallengeManager(IChallengeManager challengeManager_) external onlyOwner {
        challengeManager = challengeManager_;
    }

    /// @notice Sets the reward amount for the token
    /// @param tokenRewardAmount_ The reward amount to set
    function setRewardAmount(uint256 tokenRewardAmount_) external onlyOwner onlyValidRewardAmount(tokenRewardAmount_) {
        tokenRewardAmount = tokenRewardAmount_;
    }

    /// @inheritdoc IChallengeRewardStrategy
    function claimReward(
        uint256 challengeCompletionId
    )
        external
        onlyExistingChallengeCompletion(challengeCompletionId)
        onlyChallengeCompletionSubmitter(challengeCompletionId, msg.sender)
        onlyExistingReward(challengeCompletionId)
    {
        challengeManager.updateRewardStateAsClaimed(challengeCompletionId);
        // Reward claimed with the configured number of NFTs
        Challenge memory challenge = challengeManager.getChallengeByCompletion(challengeCompletionId);
        IWellnessSoulboundToken soulboundToken = IWellnessSoulboundToken(challenge.soulboundToken);
        soulboundToken.mintReward(msg.sender, tokenRewardAmount);
    }
}
