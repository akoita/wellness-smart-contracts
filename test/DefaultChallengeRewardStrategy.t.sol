// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { WellnessBaseTest } from "./WellnessBaseTest.t.sol";

import { ChallengeCompletionSubmitted } from "../src/commons/events.sol";
import {
    ChallengeCompletion,
    ChallengeCompletionStatus,
    ChallengeTheme,
    Challenge,
    PartnerSettings
} from "../src/types/DataTypes.sol";
import { IWellnessSoulboundToken } from "../src/interfaces/IWellnessSoulboundToken.sol";
import {
    NoPendingReward,
    NonExistingChallengeCompletion,
    InvalidChallengeCompletionSubmitter
} from "../src/commons/Errors.sol";

contract DefaultChallengeRewardStrategyTest is WellnessBaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_claimReward() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // register partner
        address partner = makeAddr("partner");
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        PartnerSettings memory partnerSettings = wellnessHome.getPartnerSettings(partner);
        IWellnessSoulboundToken soulboundToken = IWellnessSoulboundToken(partnerSettings.soulboundTokenAddress);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register user
        address user = makeAddr("user");
        vm.prank(user);
        wellnessHome.registerAsUser();

        // challenge completion
        ChallengeCompletion memory challengeCompletion;
        challengeCompletion.challengeId = expectedChallengeId;
        challengeCompletion.data = challengeCompletionData.berryBliss;

        uint256 expectedChallengeCompletionId = 1;
        ChallengeCompletion memory expectedChallengeCompletion = ChallengeCompletion({
            id: expectedChallengeCompletionId,
            challengeId: expectedChallengeId,
            submitter: user,
            data: challengeCompletionData.berryBliss,
            status: ChallengeCompletionStatus.UNDEFINED,
            rewarded: false,
            evaluationTime: 0
        });

        // submit challenge completion
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletionId, expectedChallengeId, user, expectedChallengeCompletion
        );
        challengeManager.submitChallengeCompletion(challengeCompletion);

        // validate challenge completion
        vm.prank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);

        ///************************************* Preconditions ******************************///
        // challenge completion should be approved
        ChallengeCompletion memory createdChallengeCompletion =
            challengeManager.getChallengeCompletion(expectedChallengeCompletionId);
        assertEq(
            uint256(createdChallengeCompletion.status),
            uint256(ChallengeCompletionStatus.SUCCESS),
            "challenge completion should be approved"
        );
        // challenge completion should have pending reward
        assertEq(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            true,
            "challenge completion should have pending reward"
        );
        // user s
        assertEq(soulboundToken.balanceOf(user), 0, "user should not have the reward yet");

        ///************************************ Action ***********************************///
        // claim reward
        vm.prank(user);
        challengeRewardStrategy.claimReward(expectedChallengeCompletionId);

        ///************************************* Postconditions ******************************///
        // user should have the reward
        assertEq(soulboundToken.balanceOf(user), 1, "user should have the reward");
        // challenge completion should not have pending reward anymore
        assertEq(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            false,
            "challenge completion should not have pending reward anymore"
        );
    }

    function test_claimReward_should_fail_if_challenge_completion_has_no_pending_reward() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // register partner
        address partner = makeAddr("partner");
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register user
        address user = makeAddr("user");
        vm.prank(user);
        wellnessHome.registerAsUser();

        // challenge completion
        ChallengeCompletion memory challengeCompletion;
        challengeCompletion.challengeId = expectedChallengeId;
        challengeCompletion.data = challengeCompletionData.berryBliss;

        uint256 expectedChallengeCompletionId = 1;
        ChallengeCompletion memory expectedChallengeCompletion = ChallengeCompletion({
            id: expectedChallengeCompletionId,
            challengeId: expectedChallengeId,
            submitter: user,
            data: challengeCompletionData.berryBliss,
            status: ChallengeCompletionStatus.UNDEFINED,
            rewarded: false,
            evaluationTime: 0
        });

        // submit challenge completion
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletionId, expectedChallengeId, user, expectedChallengeCompletion
        );
        challengeManager.submitChallengeCompletion(challengeCompletion);

        ///************************************* Preconditions ******************************///
        // challenge completion has not been evaluated yet
        assertFalse(
            challengeManager.isChallengeCompletionApproved(expectedChallengeCompletionId),
            "challenge completion should not have been evaluated yet"
        );
        // challenge completion should not have pending reward
        assertFalse(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            "challenge completion should not have pending reward"
        );

        ///************************************ Action ***********************************///
        // claim reward should fail because the challenge completion has no pending reward
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(NoPendingReward.selector, expectedChallengeCompletionId));
        challengeRewardStrategy.claimReward(expectedChallengeCompletionId);
    }

    function test_claimReward_should_fail_if_challenge_completion_reward_has_already_been_claimed() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // register partner
        address partner = makeAddr("partner");
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register user
        address user = makeAddr("user");
        vm.prank(user);
        wellnessHome.registerAsUser();

        // challenge completion
        ChallengeCompletion memory challengeCompletion;
        challengeCompletion.challengeId = expectedChallengeId;
        challengeCompletion.data = challengeCompletionData.berryBliss;

        uint256 expectedChallengeCompletionId = 1;
        ChallengeCompletion memory expectedChallengeCompletion = ChallengeCompletion({
            id: expectedChallengeCompletionId,
            challengeId: expectedChallengeId,
            submitter: user,
            data: challengeCompletionData.berryBliss,
            status: ChallengeCompletionStatus.UNDEFINED,
            rewarded: false,
            evaluationTime: 0
        });

        // submit challenge completion
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletionId, expectedChallengeId, user, expectedChallengeCompletion
        );
        challengeManager.submitChallengeCompletion(challengeCompletion);

        // validate challenge completion
        vm.prank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);

        // claim reward
        vm.prank(user);
        challengeRewardStrategy.claimReward(expectedChallengeCompletionId);

        ///******************************************* Preconditions ***********************************///
        // challenge completion reward should have been claimed
        assertEq(
            challengeManager.getChallengeCompletion(expectedChallengeCompletionId).rewarded,
            true,
            "challenge completion reward should have been claimed"
        );
        // challenge completion should not have pending reward
        assertFalse(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            "challenge completion should not have pending reward"
        );

        ///************************************ Action ***********************************///
        // claim reward again should fail
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(NoPendingReward.selector, expectedChallengeCompletionId));
        challengeRewardStrategy.claimReward(expectedChallengeCompletionId);
    }

    function test_claimReward_should_fail_if_challenge_completion_does_not_exist() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // register partner
        address partner = makeAddr("partner");
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register user
        address user = makeAddr("user");
        vm.prank(user);
        wellnessHome.registerAsUser();

        // invalid challenge completion id
        uint256 nonExistingChallengeCompletionId = 1;

        ///******************************************* Preconditions ***********************************///
        // challenge completion should not exist
        vm.expectRevert(
            abi.encodeWithSelector(NonExistingChallengeCompletion.selector, nonExistingChallengeCompletionId)
        );
        challengeManager.getChallengeCompletion(nonExistingChallengeCompletionId);

        ///******************************************* Action ***********************************///
        // claim reward for a non existing challenge completion should fail
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(NonExistingChallengeCompletion.selector, nonExistingChallengeCompletionId)
        );
        challengeRewardStrategy.claimReward(nonExistingChallengeCompletionId);
    }

    function test_claimReward_should_fail_if_challenge_completion_has_not_been_submitted_by_the_invoker() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // register partner
        address partner = makeAddr("partner");
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register user1
        address user1 = makeAddr("user1");
        vm.prank(user1);
        wellnessHome.registerAsUser();
        // register user2
        address user2 = makeAddr("user2");
        vm.prank(user2);
        wellnessHome.registerAsUser();

        // challenge completion
        ChallengeCompletion memory challengeCompletion;
        challengeCompletion.challengeId = expectedChallengeId;
        challengeCompletion.data = challengeCompletionData.berryBliss;

        uint256 expectedChallengeCompletionId = 1;

        // submit challenge completion
        vm.prank(user1);
        challengeManager.submitChallengeCompletion(challengeCompletion);

        // validate challenge completion
        vm.prank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);

        ///************************************* Preconditions ******************************///
        // user2 is not the submitter of the challenge completion
        assertTrue(
            challengeManager.getChallengeCompletion(expectedChallengeCompletionId).submitter != user2,
            "user2 is not the submitter of the challenge completion"
        );

        ///************************************ Action ***********************************///
        // claim reward should fail because user2 is not the submitter of the challenge completion
        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(InvalidChallengeCompletionSubmitter.selector, expectedChallengeCompletionId, user2)
        );
        challengeRewardStrategy.claimReward(expectedChallengeCompletionId);
    }
}
