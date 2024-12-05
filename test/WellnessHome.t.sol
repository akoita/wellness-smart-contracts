// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// import { console2 } from "forge-std/src/console2.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import {
    PartnerNotRegistered,
    PartnerAlreadyRegistered,
    PartnerRegistrationRequestNotFound,
    PartnerRegistrationRequestAlreadySubmitted,
    PartnerIsRevoked,
    UserAlreadyRegistered,
    ExistingUserWithThisAddress,
    ExistingOrRevokedPartnerWithThisAddress,
    OwnerAddressForbidden
} from "../src/commons/Errors.sol";

import { WellnessBaseTest } from "./WellnessBaseTest.t.sol";

contract WellnessHomeTest is WellnessBaseTest {
    function setUp() public override {
        super.setUp();
    }

    ///****************************************************************************************************///
    ///**************************************** requestRegistrationAsPartner ******************************///
    ///****************************************************************************************************///

    function test_requestRegistrationAsPartner() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        ///************************************* Preconditions ******************************///
        // partner registration request should not exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner),
            false,
            "partner registration request should not exist"
        );

        ///************************************ Action ***********************************///
        // partner requests registration
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        ///********************************* Postconditions ******************************///
        // partner registration request should exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner), true, "partner registration request should exist"
        );
    }

    function test_requestRegistrationAsPartner_should_fail_if_partner_registration_request_already_exists() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        // partner requests registration
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        ///************************************* Preconditions ******************************///
        // partner registration request should exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner), true, "partner registration request should exist"
        );

        ///************************************ Action ***********************************///
        // partner requests registration again: should fail
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(PartnerRegistrationRequestAlreadySubmitted.selector, partner));
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
    }

    function test_requestRegistrationAsPartner_should_fail_if_partner_is_already_registered() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        // register partner
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///************************************* Preconditions ******************************///
        // partner should be registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");

        ///************************************ Action ***********************************///
        // partner requests registration again: should fail
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(PartnerAlreadyRegistered.selector, partner));
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
    }

    function test_requestRegistrationAsPartner_should_fail_if_partner_has_been_revoked() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        // partner requests registration
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        // owner approves partner registration
        // Approve partner registration as the owner
        vm.startPrank(owner);
        wellnessHome.approvePartnerRegistration(partner);
        // Revoke partner registration as the owner
        wellnessHome.revokePartnerRegistration(partner);
        vm.stopPrank();

        ///************************************* Preconditions ******************************///
        // partner should have been revoked
        assertEq(wellnessHome.isRevokedPartner(partner), true, "partner should have been revoked");

        ///************************************ Action ***********************************///
        // trying to request registration as a partner that has been revoked should fail
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(PartnerIsRevoked.selector, partner));
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
    }

    function test_requestRegistrationAsPartner_should_fail_if_owner_address() public {
        ///************************************ Action ***********************************///
        // request partner registration as owner should fail
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(OwnerAddressForbidden.selector, owner));
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
    }

    function test_requestRegistrationAsPartner_should_fail_if_existing_user_address() public {
        ///*********************************** Fixture ***********************************///
        address user = makeAddr("user");
        vm.deal(user, 1 ether);
        vm.prank(user);
        wellnessHome.registerAsUser();

        ///************************************* Preconditions ******************************///
        // user should be registered
        assertEq(wellnessHome.isUser(user), true, "user should be registered");

        ///************************************ Action ***********************************///
        // request partner registration as user should fail
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(ExistingUserWithThisAddress.selector, user));
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
    }

    ///****************************************************************************************************///
    ///*********************************** approvePartnerRegistration
    /// *************************************///
    ///****************************************************************************************************///

    function test_approvePartnerRegistration() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        // partner requests registration
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        ///********************************* Preconditions *******************************///
        // partner should not be registered
        assertEq(wellnessHome.isPartner(partner), false, "partner should not be registered");
        // partner registration request should exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner), true, "partner registration request should exist"
        );

        ///************************************ Action ***********************************///
        // owner approves partner registration
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///********************************* Postconditions ******************************///
        // partner should be registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");
        // partner registration request should not exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner),
            false,
            "partner registration request should not exist"
        );
    }

    function test_approvePartnerRegistration_should_fail_if_not_owner() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        // partner requests registration
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");

        ///********************************* Preconditions *******************************///
        // partner should not be registered
        assertEq(wellnessHome.isPartner(partner), false, "partner should not be registered");
        // partner registration request should exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner), true, "partner registration request should exist"
        );

        ///************************************ Action ***********************************///
        // trying to approve partner registration as non-owner should fail
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, partner));
        wellnessHome.approvePartnerRegistration(partner);
    }

    function test_approvePartnerRegistration_should_fail_if_partner_registration_request_does_not_exist() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");

        ///********************************* Preconditions *******************************///
        // partner registration request should not exist
        assertEq(
            wellnessHome.partnerRegistrationRequestExists(partner),
            false,
            "partner registration request should not exist"
        );

        ///************************************ Action ***********************************///
        // trying to approve registration request that does not exist should fail
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PartnerRegistrationRequestNotFound.selector, partner));
        wellnessHome.approvePartnerRegistration(partner);
    }

    ///****************************************************************************************************///
    ///************************************ revokePartnerRegistration *************************************///
    ///****************************************************************************************************///
    function test_revokePartnerRegistration() public {
        ///*********************************** Fixture ***********************************///
        // register partner
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///********************************* Preconditions *******************************///
        // partner should be registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");

        ///************************************ Action ***********************************///
        // owner revokes partner registration
        vm.prank(owner);
        wellnessHome.revokePartnerRegistration(partner);
    }

    function test_revokePartnerRegistration_should_fail_if_not_owner() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///********************************* Preconditions *******************************///
        // partner should be registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");

        ///************************************ Action ***********************************///
        // trying to revoke partner registration as non-owner should fail
        address nonOwner = makeAddr("nonOwner");
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        wellnessHome.revokePartnerRegistration(partner);
    }

    function test_revokePartnerRegistration_should_fail_if_partner_is_not_registered() public {
        ///*********************************** Fixture ***********************************///
        address partner = makeAddr("partner");

        ///********************************* Preconditions *******************************///
        // partner should not be registered
        assertEq(wellnessHome.isPartner(partner), false, "partner should not be registered");

        ///************************************ Action ***********************************///
        // trying to revoke registration of a partner that is not registered should fail
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PartnerNotRegistered.selector, partner));
        wellnessHome.revokePartnerRegistration(partner);
    }

    ///****************************************************************************************************///
    ///****************************************** registerAsUser
    /// ******************************************///
    ///****************************************************************************************************///

    function test_registerAsUser() public {
        ///************************************* Fixture ***********************************///
        address user = makeAddr("user");

        ///************************************* Preconditions ******************************///
        // user should not be registered
        assertEq(wellnessHome.isUser(user), false, "user should not be registered");

        ///************************************ Action ***********************************///
        vm.prank(user);
        wellnessHome.registerAsUser();

        ///********************************* Postconditions ******************************///
        // user should be registered
        assertEq(wellnessHome.isUser(user), true, "user should be registered");
    }

    function test_registerAsUser_should_fail_if_user_already_registered() public {
        ///************************************* Fixture ***********************************///
        address user = makeAddr("user");
        vm.prank(user);
        wellnessHome.registerAsUser();

        ///********************************* Preconditions *******************************///
        // user should be registered
        assertEq(wellnessHome.isUser(user), true, "user should be registered");

        ///************************************ Action ***********************************///
        // trying to register as a user that is already registered should fail
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(UserAlreadyRegistered.selector, user));
        wellnessHome.registerAsUser();
    }

    function test_registerAsUser_should_fail_if_partner_address() public {
        ///************************************* Fixture ***********************************///
        address partner = makeAddr("partner");
        vm.deal(partner, 1 ether);
        vm.prank(partner);
        wellnessHome.requestRegistrationAsPartner{ value: partnerRegistrationFee }("name", "symbol");
        vm.prank(owner);
        wellnessHome.approvePartnerRegistration(partner);

        ///********************************* Preconditions *******************************///
        // partner should be registered
        assertEq(wellnessHome.isPartner(partner), true, "partner should be registered");

        ///************************************ Action ***********************************///
        // trying to register partner as a user should fail
        vm.prank(partner);
        vm.expectRevert(abi.encodeWithSelector(ExistingOrRevokedPartnerWithThisAddress.selector, partner));
        wellnessHome.registerAsUser();
    }

    function test_registerAsUser_should_fail_if_owner_address() public {
        ///************************************ Action ***********************************///
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(OwnerAddressForbidden.selector, owner));
        wellnessHome.registerAsUser();
    }
}
