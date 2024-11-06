// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWellnessHome } from "./interfaces/IWellnessHome.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { WellnessSoulboundToken } from "./WellnessSoulboundToken.sol";

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
} from "./commons/Errors.sol";

contract WellnessHome is Ownable, IWellnessHome {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PartnerSettings {
        string soulboundTokenName;
        string soulboundTokenSymbol;
        address soulboundTokenAddress;
        string logoUrl;
        string logoSVG;
    }

    // Declare a set state variable
    EnumerableSet.AddressSet internal partners;
    mapping(address => PartnerSettings) internal partnerSettings;
    EnumerableSet.AddressSet internal partnerRegistrationRequests;
    EnumerableSet.AddressSet internal revokedPartners;
    EnumerableSet.AddressSet internal users;

    // Modifiers

    modifier onlyExistingPartner(address partner) {
        require(partners.contains(partner), PartnerNotRegistered(partner));
        _;
    }

    modifier onlyNotExistingPartner(address partner) {
        require(!partners.contains(partner), PartnerAlreadyRegistered(partner));
        _;
    }

    modifier onlyExistingPartnerRegistrationRequest(address partner) {
        require(partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestNotFound(partner));
        _;
    }

    modifier onlyNotExistingPartnerRegistrationRequest(address partner) {
        require(!partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestAlreadySubmitted(partner));
        _;
    }

    modifier onlyNotRevokedPartner(address partner) {
        require(!revokedPartners.contains(partner), PartnerIsRevoked(partner));
        _;
    }

    modifier onlyNotExistingUser(address user) {
        require(!isUser(user), UserAlreadyRegistered(user));
        _;
    }

    modifier onlyNonUser(address partner) {
        require(!isUser(partner), ExistingUserWithThisAddress(partner));
        _;
    }

    modifier onlyNonPartner(address user) {
        require(!isPartner(user) && !isRevokedPartner(user), ExistingOrRevokedPartnerWithThisAddress(user));
        _;
    }

    modifier onlyNonOwner(address account) {
        require(account != owner(), OwnerAddressForbidden(account));
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {
        //
    }

    function requestRegistrationAsPartner(
        string memory nftName,
        string memory nftSymbol
    )
        external
        onlyNotExistingPartner(msg.sender)
        onlyNotExistingPartnerRegistrationRequest(msg.sender)
        onlyNotRevokedPartner(msg.sender)
        onlyNonOwner(msg.sender)
        onlyNonUser(msg.sender)
    {
        partnerRegistrationRequests.add(msg.sender);
        partnerSettings[msg.sender] = PartnerSettings({
            soulboundTokenName: nftName,
            soulboundTokenSymbol: nftSymbol,
            soulboundTokenAddress: address(0),
            logoUrl: "",
            logoSVG: ""
        });
    }

    function approvePartnerRegistration(
        address partner
    )
        external
        onlyOwner
        onlyExistingPartnerRegistrationRequest(partner)
    {
        partnerRegistrationRequests.remove(partner);
        partners.add(partner);
        // Define the Soulbound Token instance for the partner
        PartnerSettings storage arguments = partnerSettings[partner];
        WellnessSoulboundToken soulboundToken =
            new WellnessSoulboundToken(owner(), arguments.soulboundTokenName, arguments.soulboundTokenSymbol);
        arguments.soulboundTokenAddress = address(soulboundToken);
    }

    function revokePartnerRegistration(address partner) external onlyOwner onlyExistingPartner(partner) {
        partners.remove(partner);
        revokedPartners.add(partner);
    }

    function registerAsUser()
        external
        onlyNotExistingUser(msg.sender)
        onlyNonPartner(msg.sender)
        onlyNonOwner(msg.sender)
    {
        users.add(msg.sender);
    }

    /// @inheritdoc IWellnessHome
    function isPartner(address partner) public view returns (bool) {
        return partners.contains(partner);
    }

    function isRevokedPartner(address partner) public view returns (bool) {
        return revokedPartners.contains(partner);
    }

    /// @inheritdoc IWellnessHome
    function isUser(address user) public view returns (bool) {
        return users.contains(user);
    }
}
