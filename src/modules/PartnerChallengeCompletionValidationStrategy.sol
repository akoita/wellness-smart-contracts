// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IChallengeCompletionValidationStrategy } from "../interfaces/IChallengeCompletionValidationStrategy.sol";
import { IChallengeManager } from "../interfaces/IChallengeManager.sol";
import { IWellnessHome } from "../interfaces/IWellnessHome.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NonExistingChallengeCompletion, InvalidChallengeSubmitter } from "../commons/Errors.sol";
import { ChallengeCompletion, Challenge } from "../types/DataTypes.sol";

/// @title PartnerChallengeCompletionValidationStrategy
/// @dev Implements the IChallengeCompletionValidationStrategy interface for validating challenge completions
contract PartnerChallengeCompletionValidationStrategy is Ownable, IChallengeCompletionValidationStrategy {
    // State variables
    IWellnessHome public wellnessHome;
    IChallengeManager public challengeManager;

    // Modifiers
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

    /// @dev Modifier to ensure the caller is the submitter of the challenge
    /// @param challengeCompletionId The ID of the challenge completion
    /// @param submitter The address of the submitter
    // slither-disable-next-line incorrect-modifier
    modifier onlyChallengeSubmitter(uint256 challengeCompletionId, address submitter) {
        ChallengeCompletion memory challengeCompletion = challengeManager.getChallengeCompletion(challengeCompletionId);
        Challenge memory challenge = challengeManager.getChallenge(challengeCompletion.challengeId);
        require(
            address(0) != submitter && submitter == challenge.submitter,
            InvalidChallengeSubmitter(challengeCompletion.challengeId, msg.sender)
        );
        _;
    }

    // Constructor
    /// @notice Constructor to initialize the contract with the owner
    /// @param owner The address of the contract owner
    constructor(address owner) Ownable(owner) { }

    // External functions
    /// @notice Sets the wellness home contract
    /// @param wellnessHome_ The address of the wellness home contract
    function setWellnessHome(IWellnessHome wellnessHome_) external onlyOwner {
        wellnessHome = wellnessHome_;
    }

    /// @notice Sets the challenge manager contract
    /// @param challengeManager_ The address of the challenge manager contract
    function setChallengeManager(IChallengeManager challengeManager_) external onlyOwner {
        challengeManager = challengeManager_;
    }

    /// @inheritdoc IChallengeCompletionValidationStrategy
    function hasChallengeCompletionMetRequirements(uint256 challengeCompletionId) external view returns (bool) {
        return challengeManager.isChallengeCompletionApproved(challengeCompletionId);
    }

    /// @notice Evaluates the challenge completion
    /// @param challengeCompletionId The ID of the challenge completion
    /// @param approved Boolean indicating if the challenge completion is approved
    function evaluateChallengeCompletion(
        uint256 challengeCompletionId,
        bool approved
    )
        external
        onlyExistingChallengeCompletion(challengeCompletionId)
        onlyChallengeSubmitter(challengeCompletionId, msg.sender)
    {
        challengeManager.evaluateChallengeCompletion(challengeCompletionId, approved);
    }
}
