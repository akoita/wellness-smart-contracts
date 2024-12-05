// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// import { console2 } from "forge-std/src/console2.sol";

import { WellnessBaseTest } from "./WellnessBaseTest.t.sol";

import {
    Challenge,
    ChallengeTheme,
    ChallengeState,
    PartnerSettings,
    ChallengeCompletion,
    ChallengeCompletionStatus
} from "../src/types/DataTypes.sol";

import {
    InvalidPartner,
    InvalidInputChallenge,
    NonExistingChallenge,
    ExpectedPendingChallenge,
    InvalidChallengeSubmitter,
    InvalidUser,
    ChallengeMaxWinnersReached
} from "../src/commons/Errors.sol";

import {
    ChallengeSubmitted,
    ChallengeStarted,
    ChallengeCancelled,
    ChallengeCompletionSubmitted
} from "../src/commons/events.sol";

contract ChallengeManagerTest is WellnessBaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_submitChallenge() public {
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

        // approve partner registration
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        uint256 expectedChallengeId = 1;
        PartnerSettings memory partnerSettings = wellnessHome.getPartnerSettings(partner);
        Challenge memory expectedChallenge = Challenge({
            id: expectedChallengeId,
            submitter: partner,
            soulboundToken: partnerSettings.soulboundTokenAddress,
            theme: challenge.theme,
            title: challenge.title,
            description: challenge.description,
            target: challenge.target,
            tokenRewardAmount: 1,
            duration: challenge.duration,
            startTime: 0,
            maxWinners: challenge.maxWinners,
            state: ChallengeState.PENDING
        });

        ///************************************* Preconditions ******************************///
        // partner is registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");
        // challenge should not exist
        assertEq(challengeManager.challengeExists(challenge.id), false, "challenge should not exist");

        ///************************************ Action ***********************************///
        vm.prank(partner);
        vm.expectEmit(true, true, true, true);
        emit ChallengeSubmitted(expectedChallengeId, partner, challenge.theme, expectedChallenge);
        challengeManager.submitChallenge(challenge);

        ///************************************* Postconditions ******************************///
        // challenge should be created
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        assertEq(createdChallenge.id, expectedChallengeId, "created challenge id is unexpected");
        assertEq(uint256(createdChallenge.theme), uint256(challenge.theme), "challenge theme should be the same");
        assertEq(createdChallenge.title, "challenge title", "challenge title should be the same");
        assertEq(createdChallenge.description, "challenge description", "challenge description should be the same");
        assertEq(createdChallenge.target, "challenge target", "challenge target should be the same");
        assertEq(createdChallenge.tokenRewardAmount, 1, "challenge token reward amount should be 1");
        assertEq(createdChallenge.duration, 1 days, "challenge duration should be 1 days");
        assertEq(createdChallenge.startTime, 0, "challenge start time should be 0");
        assertEq(createdChallenge.maxWinners, 3, "challenge max winners should be 3");
        assertEq(uint256(createdChallenge.state), uint256(ChallengeState.PENDING), "challenge state should be pending");
    }

    function test_submitChallenge_should_fail_if_invalid_partner() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 8 days;
        challenge.maxWinners = 3;
        challenge.tokenRewardAmount = 1;

        // register partner
        address partner = makeAddr("partner");

        ///************************************* Preconditions ******************************///
        // partner should not be registered
        assertEq(wellnessHome.isPartner(partner), false, "partner should not be registered");

        ///************************************ Action ***********************************///
        // submit challenge should fail if invalid partner
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(InvalidPartner.selector, partner));
        challengeManager.submitChallenge(challenge);
    }

    function test_submitChallenge_should_fail_if_invalid_challenge_input() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;

        // register partner
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        // approve partner registration
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///************************************* Preconditions ******************************///
        // partner is registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");

        ///************************************ Action ***********************************///
        // submit challenge should fail if invalid title
        vm.startPrank(partner);
        vm.expectRevert(abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge title is required"));
        challengeManager.submitChallenge(challenge);
        // submit challenge should fail if invalid description
        challenge.title = "challenge title";
        vm.expectRevert(abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge description is required"));
        challengeManager.submitChallenge(challenge);
        // submit challenge should fail if invalid target
        challenge.description = "challenge description";
        vm.expectRevert(
            abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge target (product or service) is required")
        );
        challengeManager.submitChallenge(challenge);
        // submit challenge should fail if invalid max winners
        challenge.target = "challenge target";
        vm.expectRevert(
            abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge max winners must be greater than 0")
        );
        challengeManager.submitChallenge(challenge);
        // submit challenge should fail if invalid duration (less than min duration)
        challenge.maxWinners = 3;
        challenge.duration = 0;
        vm.expectRevert(abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge duration less than minimum"));
        challengeManager.submitChallenge(challenge);
        // submit challenge should fail if invalid duration (greater than max duration)
        challenge.duration = 11 days;
        vm.expectRevert(
            abi.encodeWithSelector(InvalidInputChallenge.selector, "Challenge duration greater than maximum")
        );
        challengeManager.submitChallenge(challenge);
        vm.stopPrank();
    }

    function test_startChallenge() public {
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

        // approve partner registration
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        uint256 expectedChallengeId = 1;

        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // challenge should be pending
        assertEq(uint256(createdChallenge.state), uint256(ChallengeState.PENDING), "challenge state should be pending");
        // challenge start time should be 0
        assertEq(createdChallenge.startTime, 0, "challenge start time should be 0");

        ///************************************ Action ***********************************///
        vm.prank(partner);
        vm.expectEmit(true, true, false, false);
        emit ChallengeStarted(expectedChallengeId, block.timestamp);
        challengeManager.startChallenge(expectedChallengeId);
        vm.stopPrank();

        ///************************************* Postconditions ******************************///
        // challenge should be in progress
        Challenge memory startedChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(
            uint256(startedChallenge.state),
            uint256(ChallengeState.IN_PROGRESS),
            "challenge state should be in progress"
        );
        // challenge start time should be set
        assertEq(startedChallenge.startTime, block.timestamp, "challenge start time should be set");
    }

    function test_startChallenge_should_fail_if_partner_is_not_registered() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;
        address invalidPartner = makeAddr("invalidPartner");

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // invalid partner should not be registered
        assertEq(wellnessHome.isPartner(invalidPartner), false, "invalid partner should not be registered");

        ///************************************ Action ***********************************///
        // invalid partner should not be able to start challenge
        vm.prank(invalidPartner);
        vm.expectRevert(abi.encodeWithSelector(InvalidChallengeSubmitter.selector, expectedChallengeId, invalidPartner));
        challengeManager.startChallenge(expectedChallengeId);
    }

    function test_startChallenge_should_fail_if_partner_is_not_submitter() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;

        // create another partner
        address anotherPartner = makeAddr("anotherPartner");
        vm.deal(anotherPartner, 1 ether);
        vm.prank(anotherPartner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(anotherPartner);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // another partner should be registered
        assertEq(wellnessHome.isPartner(anotherPartner), true, "another partner should be registered");
        // another partner is not submitter
        vm.assertNotEq(createdChallenge.submitter, anotherPartner, "another partner is not challenge submitter");

        ///************************************ Action ***********************************///
        // another partner should not be able to start challenge
        vm.prank(anotherPartner);
        vm.expectRevert(abi.encodeWithSelector(InvalidChallengeSubmitter.selector, expectedChallengeId, anotherPartner));
        challengeManager.startChallenge(expectedChallengeId);
    }

    function test_startChallenge_should_fail_if_challenge_does_not_exist() public {
        ///*********************************** Fixture ***********************************///
        uint256 invalidChallengeId = 1;

        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///************************************* Preconditions ******************************///
        // no corresponding challenge should exist
        assertEq(challengeManager.challengeExists(invalidChallengeId), false, "challenge should not exist");

        ///************************************ Action ***********************************///
        // start challenge should fail if challenge is not existing
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(NonExistingChallenge.selector, invalidChallengeId));
        challengeManager.startChallenge(invalidChallengeId);
    }

    function test_startChallenge_should_fail_if_challenge_is_not_pending() public {
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;

        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        assertEq(challengeManager.challengeExists(expectedChallengeId), true, "challenge should exist");
        // challenge should be in progress
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(
            uint256(createdChallenge.state),
            uint256(ChallengeState.IN_PROGRESS),
            "challenge state should be in progress"
        );

        ///************************************ Action ***********************************///
        // start challenge should fail because challenge is not pending
        vm.prank(partner);
        vm.expectRevert(
            abi.encodeWithSelector(ExpectedPendingChallenge.selector, expectedChallengeId, ChallengeState.IN_PROGRESS)
        );
        challengeManager.startChallenge(expectedChallengeId);
    }

    function test_cancelChallenge() public {
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

        // approve partner registration
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        uint256 expectedChallengeId = 1;

        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // challenge should be pending
        assertEq(uint256(createdChallenge.state), uint256(ChallengeState.PENDING), "challenge state should be pending");

        ///************************************ Action ***********************************///
        vm.prank(partner);
        vm.expectEmit(true, true, false, false);
        emit ChallengeCancelled(expectedChallengeId, block.timestamp);
        challengeManager.cancelChallenge(expectedChallengeId);
        vm.stopPrank();

        ///************************************* Postconditions ******************************///
        // challenge should be cancelled
        Challenge memory cancelledChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(
            uint256(cancelledChallenge.state), uint256(ChallengeState.CANCELLED), "challenge state should be cancelled"
        );
    }

    function test_cancelChallenge_should_fail_if_partner_is_not_registered() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;
        address invalidPartner = makeAddr("invalidPartner");

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // invalid partner should not be registered
        assertEq(wellnessHome.isPartner(invalidPartner), false, "invalid partner should not be registered");

        ///************************************ Action ***********************************///
        // invalid partner should not be able to cancel challenge
        vm.prank(invalidPartner);
        vm.expectRevert(abi.encodeWithSelector(InvalidChallengeSubmitter.selector, expectedChallengeId, invalidPartner));
        challengeManager.cancelChallenge(expectedChallengeId);
    }

    function test_cancelChallenge_should_fail_if_partner_is_not_submitter() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;

        // create another partner
        address anotherPartner = makeAddr("anotherPartner");
        vm.deal(anotherPartner, 1 ether);
        vm.prank(anotherPartner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(anotherPartner);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(challengeManager.challengeExists(createdChallenge.id), true, "challenge should exist");
        // another partner should be registered
        assertEq(wellnessHome.isPartner(anotherPartner), true, "another partner should be registered");
        // another partner is not submitter
        vm.assertNotEq(createdChallenge.submitter, anotherPartner, "another partner is not challenge submitter");

        ///************************************ Action ***********************************///
        // another partner should not be able to cancel challenge
        vm.prank(anotherPartner);
        vm.expectRevert(abi.encodeWithSelector(InvalidChallengeSubmitter.selector, expectedChallengeId, anotherPartner));
        challengeManager.cancelChallenge(expectedChallengeId);
    }

    function test_cancelChallenge_should_fail_if_challenge_does_not_exist() public {
        ///*********************************** Fixture ***********************************///
        uint256 invalidChallengeId = 1;

        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///************************************* Preconditions ******************************///
        // no corresponding challenge should exist
        assertEq(challengeManager.challengeExists(invalidChallengeId), false, "challenge should not exist");

        ///************************************ Action ***********************************///
        // cancel challenge should fail if challenge is not existing
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(NonExistingChallenge.selector, invalidChallengeId));
        challengeManager.cancelChallenge(invalidChallengeId);
    }

    function test_cancelChallenge_should_fail_if_challenge_is_not_pending() public {
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 3;

        // submit challenge
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        vm.prank(partner);
        challengeManager.submitChallenge(challenge);

        uint256 expectedChallengeId = 1;

        // start challenge
        vm.prank(partner);
        challengeManager.startChallenge(expectedChallengeId);

        ///************************************* Preconditions ******************************///
        // challenge should exist
        assertEq(challengeManager.challengeExists(expectedChallengeId), true, "challenge should exist");
        // challenge should be in progress
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(
            uint256(createdChallenge.state),
            uint256(ChallengeState.IN_PROGRESS),
            "challenge state should be in progress"
        );

        ///************************************ Action ***********************************///
        // start challenge should fail because challenge is not pending
        vm.prank(partner);
        vm.expectRevert(
            abi.encodeWithSelector(ExpectedPendingChallenge.selector, expectedChallengeId, ChallengeState.IN_PROGRESS)
        );
        challengeManager.startChallenge(expectedChallengeId);
    }

    function test_submitChallengeCompletion() public {
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

        ///************************************* Preconditions ******************************///
        // challenge should be in progress
        Challenge memory createdChallenge = challengeManager.getChallenge(expectedChallengeId);
        assertEq(
            uint256(createdChallenge.state),
            uint256(ChallengeState.IN_PROGRESS),
            "challenge state should be in progress"
        );
        // user should not have submitted any challenge completion yet
        uint256[] memory userChallengeCompletions = challengeManager.getUserChallengeCompletions(user);
        vm.assertEq(userChallengeCompletions.length, 0, "user should not have submitted any challenge completion yet");
        // challenge completion should not exist
        assertEq(
            challengeManager.challengeCompletionExists(expectedChallengeCompletionId),
            false,
            "challenge completion should not exist"
        );
        // challenge completions by challenge should be empty
        uint256[] memory challengeCompletions = challengeManager.getChallengeCompletionsByChallenge(expectedChallengeId);
        assertEq(challengeCompletions.length, 0, "challenge completions by challenge should be empty");

        ///************************************ Action ***********************************///
        // submit challenge completion
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit ChallengeCompletionSubmitted(
            expectedChallengeCompletionId, expectedChallengeId, user, expectedChallengeCompletion
        );
        challengeManager.submitChallengeCompletion(challengeCompletion);

        ///************************************* Postconditions ******************************///
        // user should have submitted one challenge completion
        userChallengeCompletions = challengeManager.getUserChallengeCompletions(user);
        assertEq(userChallengeCompletions.length, 1, "user should have submitted one challenge completion");
        // challenge completion should be created
        ChallengeCompletion memory createdChallengeCompletion =
            challengeManager.getChallengeCompletion(userChallengeCompletions[0]);
        assertEq(
            createdChallengeCompletion.challengeId, expectedChallengeId, "challenge completion should have expected id"
        );
        assertEq(
            createdChallengeCompletion.data,
            challengeCompletionData.berryBliss,
            "challenge completion should have expected data"
        );
        assertEq(createdChallengeCompletion.submitter, user, "challenge completion should have expected submitter");
        assertEq(
            uint256(createdChallengeCompletion.status),
            uint256(ChallengeCompletionStatus.UNDEFINED),
            "challenge completion should have expected status"
        );
        assertEq(createdChallengeCompletion.rewarded, false, "challenge completion should not be rewarded yet");
        // challenge completion should exist
        assertEq(
            challengeManager.challengeCompletionExists(expectedChallengeCompletionId),
            true,
            "challenge completion should exist"
        );
        // challenge completion should be inserted into challenge completions mapping
        challengeCompletions = challengeManager.getChallengeCompletionsByChallenge(expectedChallengeId);
        assertEq(challengeCompletions.length, 1, "challenge should have one challenge completion");
        assertEq(
            challengeCompletions[0],
            createdChallengeCompletion.id,
            "challenge completion should be the first in the list"
        );
        // user should have one challenge completion
        userChallengeCompletions = challengeManager.getUserChallengeCompletions(user);
        assertEq(userChallengeCompletions.length, 1, "user should have one challenge completion");
        assertEq(
            userChallengeCompletions[0],
            createdChallengeCompletion.id,
            "challenge completion should be the first in the list"
        );
    }

    function test_submitChallengeCompletion_should_fail_if_invalid_user() public {
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

        // challenge completion
        ChallengeCompletion memory challengeCompletion;
        challengeCompletion.challengeId = expectedChallengeId;
        challengeCompletion.data = challengeCompletionData.berryBliss;

        // invalid user
        address invalidUser = makeAddr("invalidUser");

        ///************************************* Preconditions ******************************///
        // invalid user should not be registered
        assertEq(wellnessHome.isUser(invalidUser), false, "invalid user should not be registered");

        ///************************************ Action ***********************************///
        // invalid user should not be able to submit challenge completion
        vm.prank(invalidUser);
        vm.expectRevert(abi.encodeWithSelector(InvalidUser.selector, invalidUser));
        challengeManager.submitChallengeCompletion(challengeCompletion);
    }

    function test_submitChallengeCompletion_should_fail_if_challenge_is_not_in_progress() public {
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
    }

    function test_submitChallengeCompletion_should_fail_if_max_winners_is_reached() public {
        ///*********************************** Fixture ***********************************///
        Challenge memory challenge;
        challenge.theme = ChallengeTheme.NUTRITION;
        challenge.title = "challenge title";
        challenge.description = "challenge description";
        challenge.target = "challenge target";
        challenge.duration = 1 days;
        challenge.maxWinners = 2;

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

        // register user1
        address user1 = makeAddr("user1");
        vm.prank(user1);
        wellnessHome.registerAsUser();
        // register user2
        address user2 = makeAddr("user2");
        vm.prank(user2);
        wellnessHome.registerAsUser();
        // register user3
        address user3 = makeAddr("user3");
        vm.prank(user3);
        wellnessHome.registerAsUser();

        // challenge completion by user1
        ChallengeCompletion memory challengeCompletion1;
        challengeCompletion1.challengeId = expectedChallengeId;
        challengeCompletion1.data = challengeCompletionData.berryBliss;
        // challenge completion by user2
        ChallengeCompletion memory challengeCompletion2;
        challengeCompletion2.challengeId = expectedChallengeId;
        challengeCompletion2.data = challengeCompletionData.energyBoost;
        // challenge completion by user3
        ChallengeCompletion memory challengeCompletion3;
        challengeCompletion3.challengeId = expectedChallengeId;
        challengeCompletion3.data = challengeCompletionData.freshStart;

        uint256 expectedChallengeCompletionId1 = 1;
        uint256 expectedChallengeCompletionId2 = 2;

        // submit challenge completions
        vm.prank(user1);
        challengeManager.submitChallengeCompletion(challengeCompletion1);
        vm.prank(user2);
        challengeManager.submitChallengeCompletion(challengeCompletion2);

        // approve challenge completions
        vm.startPrank(partner);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId1, true);
        challengeCompletionValidationStrategy.evaluateChallengeCompletion(expectedChallengeCompletionId2, true);
        vm.stopPrank();

        ///************************************* Preconditions ******************************///
        // we should have reached the max number of challenge configured winners
        uint256[] memory approvedChallengeCompletions =
            challengeManager.getApprovedChallengeCompletionsByChallenge(expectedChallengeId);
        assertEq(
            approvedChallengeCompletions.length,
            challenge.maxWinners,
            "we should have reached the max number of challenge configured winners"
        );

        ///************************************ Action ***********************************///
        // user3 should not be able to submit a challenge completion
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(ChallengeMaxWinnersReached.selector, expectedChallengeId, challenge.maxWinners)
        );
        challengeManager.submitChallengeCompletion(challengeCompletion3);
    }
}
