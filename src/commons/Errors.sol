// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ChallengeState } from "../types/DataTypes.sol";

error InvalidPartner(address invalidPartner);
error InvalidUser(address invalidUser);
error UserOperationNotAllowedForPartner(address user);
error UserOperationNotAllowedForOwner(address partner);

///******************************************* WellnessHome *******************************************///

error PartnerNotRegistered(address partner);
error PartnerAlreadyRegistered(address partner);
error PartnerRegistrationRequestNotFound(address partner);
error PartnerRegistrationRequestAlreadySubmitted(address partner);
error PartnerIsRevoked(address partner);
error UserAlreadyRegistered(address user);
error ExistingUserWithThisAddress(address user);
error ExistingOrRevokedPartnerWithThisAddress(address user);
error OwnerAddressForbidden(address account);

///****************************************** ChallengeManager******************************************///
error NoPendingReward(uint256 challengeCompletionId);
error InvalidTokenRewardAmount(uint256 tokenRewardAmount);
error ChallengeCompletionValidatorRoleRequired(address account);
error NonExistingChallenge(uint256 challengeId);
error ExpectedPendingChallenge(uint256 challengeId, ChallengeState currentState);
error ExpectedStartedChallenge(uint256 challengeId);
error ChallengeMaxWinnersReached(uint256 challengeId, uint256 maxWinners);
error NonExistingChallengeCompletion(uint256 challengeCompletionId);
error NonExistingChallengeCompletionByUser(uint256 challengeCompletionId, address user);
error ChallengeCompletionAlreadySubmitted(uint256 challengeId, address user);
error ChallengeRewardStrategyRoleRequired(address account);
error ChallengeCompletionAlreadyEvaluated(uint256 challengeCompletionId);
error InvalidChallengeSubmitter(uint256 challengeId, address submitter);
error InvalidChallengeCompletionSubmitter(uint256 challengeCompletionId, address submitter);
error InvalidInputChallenge(string message);
error InvalidInputChallengeCompletion(string message);

///***************************************** WellnessSoulboundToken *****************************************///
error AdminRoleRequired(address account);
error MinterRoleRequired(address account);
