// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IChallengeRewardStrategy } from "../interfaces/IChallengeRewardStrategy.sol";
import { IChallengeManager } from "../interfaces/IChallengeManager.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWellnessSoulboundToken } from "../interfaces/IWellnessSoulboundToken.sol";
import { NoPendingReward, InvalidTokenRewardAmount, NonExistingChallengeCompletion } from "../commons/Errors.sol";

contract DefaultChallengeRewardStrategy is Ownable, IChallengeRewardStrategy {
    IChallengeManager internal challengeManager;
    IWellnessSoulboundToken internal soulboundToken;
    uint256 internal tokenRewardAmount;
    mapping(uint256 challengeCompletionId => bool isPendingReward) internal pendingRewards;

    // modifiers
    modifier onlyExistingReward(uint256 challengeCompletionId) {
        require(
            challengeManager.isChallengeCompletionApproved(challengeCompletionId),
            NonExistingChallengeCompletion(challengeCompletionId)
        );
        require(challengeManager.hasPendingReward(challengeCompletionId), NoPendingReward(challengeCompletionId));
        _;
    }

    modifier onlyValidRewardAmount(uint256 tokenRewardAmount_) {
        require(tokenRewardAmount_ > 0 && tokenRewardAmount_ <= 10, InvalidTokenRewardAmount(tokenRewardAmount_));
        _;
    }

    modifier onlyExistingChallengeCompletion(uint256 challengeCompletionId) {
        require(
            challengeManager.challengeCompletionExists(challengeCompletionId),
            NonExistingChallengeCompletion(challengeCompletionId)
        );
        _;
    }

    constructor(address owner) Ownable(owner) {
        tokenRewardAmount = 1;
    }

    function setChallengeManager(IChallengeManager challengeManager_) external onlyOwner {
        challengeManager = challengeManager_;
    }

    function setSoulboundToken(IWellnessSoulboundToken soulboundToken_) external onlyOwner {
        soulboundToken = soulboundToken_;
    }

    function setRewardAmount(uint256 tokenRewardAmount_) external onlyOwner onlyValidRewardAmount(tokenRewardAmount_) {
        tokenRewardAmount = tokenRewardAmount_;
    }

    /// @inheritdoc IChallengeRewardStrategy
    function claimReward(uint256 challengeCompletionId) external onlyExistingReward(challengeCompletionId) {
        challengeManager.updateRewardStateAsClaimed(challengeCompletionId);
        // Reward claimed with the configured number of NFTs
        soulboundToken.mintReward(msg.sender, tokenRewardAmount);
    }
}
