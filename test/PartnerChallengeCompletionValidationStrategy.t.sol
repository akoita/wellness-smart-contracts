// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { WellnessBaseTest } from "./WellnessBaseTest.t.sol";

import {
    ChallengeCompletion,
    ChallengeTheme,
    ChallengeCompletionStatus,
    Challenge,
    ChallengeState
} from "../src/types/DataTypes.sol";

import { ChallengeCompletionSubmitted } from "../src/commons/events.sol";

import {
    NonExistingChallengeCompletion,
    InvalidChallengeSubmitter,
    ChallengeCompletionAlreadyEvaluated,
    ChallengeCompletionValidatorRoleRequired,
    ChallengeMaxWinnersReached
} from "../src/commons/Errors.sol";
import { IChallengeCompletionValidationStrategy } from "../src/interfaces/IChallengeCompletionValidationStrategy.sol";
import { WellnessBaseTest } from "./WellnessBaseTest.t.sol";

contract PartnerChallengeCompletionValidationStrategyTest is WellnessBaseTest {
    struct ChallengeSetup {
        Challenge challenge;
        address partner;
        uint256 expectedChallengeId;
        address[] users;
    }

    function setUp() public override {
        super.setUp();
    }

    function test_validateChallengeCompletion() public {
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
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
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
        // challenge completion should not be approved yet
        ChallengeCompletion memory createdChallengeCompletion =
            challengeManager.getChallengeCompletion(expectedChallengeCompletionId);
        assertEq(
            uint256(createdChallengeCompletion.status),
            uint256(ChallengeCompletionStatus.UNDEFINED),
            "challenge completion should not be approved yet"
        );
        // challenge completion should not have claimable reward yet
        assertFalse(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            "challenge completion should not have claimable reward yet"
        );

        ///************************************ Action ***********************************///
        // validate challenge completion
        vm.prank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);

        ///************************************* Postconditions ******************************///
        // challenge completion should be approved
        createdChallengeCompletion = challengeManager.getChallengeCompletion(expectedChallengeCompletionId);
        assertEq(
            uint256(createdChallengeCompletion.status),
            uint256(ChallengeCompletionStatus.SUCCESS),
            "challenge completion should be approved"
        );
        // challenge completion should have claimable reward
        assertTrue(
            challengeManager.hasPendingReward(expectedChallengeCompletionId),
            "challenge completion should have claimable reward"
        );
    }

    function test_validateChallengeCompletion_should_fail_if_challenge_completion_does_not_exist() public {
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
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        uint256 nonExistingChallengeCompletionId = 1;

        ///************************************ Preconditions ******************************///
        // challenge completion should not exist
        assertFalse(
            challengeManager.challengeCompletionExists(nonExistingChallengeCompletionId),
            "challenge completion should not exist"
        );

        ///************************************ Action ***********************************///
        vm.prank(partner);
        vm.expectRevert(
            abi.encodeWithSelector(NonExistingChallengeCompletion.selector, nonExistingChallengeCompletionId)
        );
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(nonExistingChallengeCompletionId, true);
    }

    function test_validateChallengeCompletion_should_fail_if_invoker_is_not_the_challenge_submitter() public {
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
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
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

        // another partner
        address anotherPartner = makeAddr("anotherPartner");
        vm.deal(anotherPartner, 1 ether);
        vm.prank(anotherPartner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("anotherName", "anotherSymbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(anotherPartner);

        ///************************************* Preconditions ******************************///
        // another partner should not be the submitter of the challenge completed
        assertNotEq(partner, anotherPartner, "another partner should not be the submitter of the challenge completed");

        ///************************************ Action ***********************************///
        // another partner should not be able to validate the challenge completion
        vm.prank(anotherPartner);
        vm.expectRevert(abi.encodeWithSelector(InvalidChallengeSubmitter.selector, expectedChallengeId, anotherPartner));
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);
    }

    function test_validateChallengeCompletion_should_fail_if_challenge_completion_is_already_evaluated() public {
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
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        // submit challenge
        uint256 expectedChallengeId = 1;
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);
        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        // register users
        address user1 = makeAddr("user1");
        vm.prank(user1);
        wellnessHome.registerAsUser();
        address user2 = makeAddr("user2");
        vm.prank(user2);
        wellnessHome.registerAsUser();

        // 1st challenge completion
        ChallengeCompletion memory challengeCompletion1;
        challengeCompletion1.challengeId = expectedChallengeId;
        challengeCompletion1.data = challengeCompletionData.berryBliss;
        // 2nd challenge completion
        ChallengeCompletion memory challengeCompletion2;
        challengeCompletion2.challengeId = expectedChallengeId;
        challengeCompletion2.data = challengeCompletionData.energyBoost;

        uint256 expectedChallengeCompletion1Id = 1;
        uint256 expectedChallengeCompletion2Id = 2;

        ChallengeCompletion memory expectedChallengeCompletion1 = ChallengeCompletion({
            id: expectedChallengeCompletion1Id,
            challengeId: expectedChallengeId,
            submitter: user1,
            data: challengeCompletionData.berryBliss,
            status: ChallengeCompletionStatus.UNDEFINED,
            rewarded: false,
            evaluationTime: 0
        });
        ChallengeCompletion memory expectedChallengeCompletion2 = ChallengeCompletion({
            id: expectedChallengeCompletion2Id,
            challengeId: expectedChallengeId,
            submitter: user2,
            data: challengeCompletionData.energyBoost,
            status: ChallengeCompletionStatus.UNDEFINED,
            rewarded: false,
            evaluationTime: 0
        });

        // submit challenge completions
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletion1Id, expectedChallengeId, user1, expectedChallengeCompletion1
        );
        challengeManager.submitChallengeCompletion(challengeCompletion1);
        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletion2Id, expectedChallengeId, user2, expectedChallengeCompletion2
        );
        challengeManager.submitChallengeCompletion(challengeCompletion2);

        // evaluate challenge completions
        vm.startPrank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion1Id, true);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion2Id, false);
        vm.stopPrank();

        ///************************************* Preconditions ******************************///
        // challenge completions should be evaluated
        ChallengeCompletion memory createdChallengeCompletion1 =
            challengeManager.getChallengeCompletion(expectedChallengeCompletion1Id);
        ChallengeCompletion memory createdChallengeCompletion2 =
            challengeManager.getChallengeCompletion(expectedChallengeCompletion2Id);
        assertEq(
            uint256(createdChallengeCompletion1.status),
            uint256(ChallengeCompletionStatus.SUCCESS),
            "challenge completion 1 should be approved"
        );
        assertEq(
            uint256(createdChallengeCompletion2.status),
            uint256(ChallengeCompletionStatus.FAILURE),
            "challenge completion 2 should be rejected"
        );

        ///************************************ Action ***********************************///
        // challenge completion already evaluated should not be able to be evaluated again
        vm.startPrank(partner);
        vm.expectRevert(
            abi.encodeWithSelector(ChallengeCompletionAlreadyEvaluated.selector, expectedChallengeCompletion1Id)
        );
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion1Id, false);

        vm.expectRevert(
            abi.encodeWithSelector(ChallengeCompletionAlreadyEvaluated.selector, expectedChallengeCompletion2Id)
        );
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion2Id, true);
        vm.stopPrank();
    }

    function test_validateChallengeCompletion_should_fail_if_validation_role_is_not_granted() public {
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
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
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

        // Remove the challenge completion validator role from the challenge completion validation strategy
        vm.prank(owner);
        challengeManager.revokeChallengeCompletionValidatorRole(challengeCompletionValidationStrategy);

        ///************************************* Preconditions ******************************///
        // challengeCompletionValidationStrategy should not have the challenge completion validator role
        assertFalse(
            challengeManager.hasChallengeCompletionValidatorRole(
                IChallengeCompletionValidationStrategy(address(challengeCompletionValidationStrategy))
            ),
            "challengeCompletionValidationStrategy should not have the challenge completion validator role"
        );

        ///************************************ Action ***********************************///
        // try to validate challenge completion: should revert if the validation role is not granted
        vm.prank(partner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ChallengeCompletionValidatorRoleRequired.selector, address(challengeCompletionValidationStrategy)
            )
        );
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId, true);
    }

    function test_validateChallengeCompletion_should_fail_if_challenge_is_max_winners_reached() public {
        ///*********************************** Fixture ***********************************///

        ChallengeSetup memory setup = ChallengeSetup({
            challenge: Challenge({
                theme: ChallengeTheme.NUTRITION,
                title: "challenge title",
                description: "challenge description",
                target: "challenge target",
                duration: 1 days,
                maxWinners: 2,
                id: 0,
                submitter: address(0),
                soulboundToken: address(0),
                tokenRewardAmount: 0,
                startTime: 0,
                state: ChallengeState.PENDING
            }),
            partner: makeAddr("partner"),
            expectedChallengeId: 1,
            users: new address[](3)
        });

        vm.deal(setup.partner, 1 ether);

        setup.users[0] = makeAddr("user1");
        setup.users[1] = makeAddr("user2");
        setup.users[2] = makeAddr("user3");

        // register partner
        vm.prank(setup.partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(setup.partner);

        // submit challenge
        vm.prank(setup.partner);
        challengeManager.submitChallenge(setup.challenge);
        // start challenge
        vm.prank(setup.partner);
        challengeManager.startChallenge(setup.expectedChallengeId);

        // register users
        for (uint256 i = 0; i < setup.users.length; i++) {
            vm.prank(setup.users[i]);
            wellnessHome.registerAsUser();
        }

        // user1 challenge completion
        ChallengeCompletion memory challengeCompletion1;
        challengeCompletion1.challengeId = setup.expectedChallengeId;
        challengeCompletion1.data = challengeCompletionData.berryBliss;
        // user2 challenge completion
        ChallengeCompletion memory challengeCompletion2;
        challengeCompletion2.challengeId = setup.expectedChallengeId;
        challengeCompletion2.data = challengeCompletionData.energyBoost;
        // user3 challenge completion
        ChallengeCompletion memory challengeCompletion3;
        challengeCompletion3.challengeId = setup.expectedChallengeId;
        challengeCompletion3.data = challengeCompletionData.energyBoost;

        uint256 expectedChallengeCompletion1Id = 1;
        uint256 expectedChallengeCompletion2Id = 2;
        uint256 expectedChallengeCompletion3Id = 3;

        // submit challenge completions
        vm.prank(setup.users[0]);
        challengeManager.submitChallengeCompletion(challengeCompletion1);
        vm.prank(setup.users[1]);
        challengeManager.submitChallengeCompletion(challengeCompletion2);
        vm.prank(setup.users[2]);
        challengeManager.submitChallengeCompletion(challengeCompletion3);

        // validate challenge completions
        vm.startPrank(setup.partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion1Id, true);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion2Id, true);
        vm.stopPrank();
        ///************************************* Preconditions ******************************///
        // challenge max winners should be reached
        uint256[] memory approvedChallengeCompletions =
            challengeManager.getApprovedChallengeCompletionsByChallenge(setup.expectedChallengeId);
        assertEq(
            approvedChallengeCompletions.length, setup.challenge.maxWinners, "challenge max winners should be reached"
        );

        ///************************************ Action ***********************************///
        // try to validate another challenge completion: should revert if the challenge max winners is reached
        vm.prank(setup.partner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ChallengeMaxWinnersReached.selector, setup.expectedChallengeId, setup.challenge.maxWinners
            )
        );
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletion3Id, true);
    }
}
