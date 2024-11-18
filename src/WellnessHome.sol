// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWellnessHome } from "./interfaces/IWellnessHome.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { WellnessSoulboundToken } from "./WellnessSoulboundToken.sol";
import { PartnerSettings } from "./types/DataTypes.sol";

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

/// @title WellnessHome
/// @dev Manages partner and user registrations
contract WellnessHome is Ownable, IWellnessHome {
    using EnumerableSet for EnumerableSet.AddressSet;

    // State variables
    EnumerableSet.AddressSet internal _partners;
    mapping(address partner => PartnerSettings partnerSettings) internal _partnersSettings;
    EnumerableSet.AddressSet internal _partnerRegistrationRequests;
    EnumerableSet.AddressSet internal _revokedPartners;
    EnumerableSet.AddressSet internal _users;

    // Modifiers
    modifier onlyExistingPartner(address partner) {
        require(_partners.contains(partner), PartnerNotRegistered(partner));
        _;
    }

    modifier onlyNotExistingPartner(address partner) {
        require(!_partners.contains(partner), PartnerAlreadyRegistered(partner));
        _;
    }

    modifier onlyExistingPartnerRegistrationRequest(address partner) {
        require(_partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestNotFound(partner));
        _;
    }

    modifier onlyNotExistingPartnerRegistrationRequest(address partner) {
        require(!_partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestAlreadySubmitted(partner));
        _;
    }

    modifier onlyNotRevokedPartner(address partner) {
        require(!_revokedPartners.contains(partner), PartnerIsRevoked(partner));
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

    // Constructor
    constructor(address initialOwner) Ownable(initialOwner) { }

    // External functions
    /// @inheritdoc IWellnessHome
    function getPartnerSettings(
        address partner
    )
        external
        view
        onlyExistingPartner(partner)
        returns (PartnerSettings memory)
    {
        return _partnersSettings[partner];
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
        _partnerRegistrationRequests.add(msg.sender);
        _partnersSettings[msg.sender] = PartnerSettings({
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
        _partnerRegistrationRequests.remove(partner);
        _partners.add(partner);
        PartnerSettings storage arguments = _partnersSettings[partner];
        // TODO: use the clone proxy to instantiate the soulbound token, much more gas efficient:
        // https://docs.openzeppelin.com/contracts/5.x/api/proxy#Clones
        WellnessSoulboundToken soulboundToken =
            new WellnessSoulboundToken(owner(), arguments.soulboundTokenName, arguments.soulboundTokenSymbol);
        arguments.soulboundTokenAddress = address(soulboundToken);
    }

    function revokePartnerRegistration(address partner) external onlyOwner onlyExistingPartner(partner) {
        _partners.remove(partner);
        _revokedPartners.add(partner);
    }

    function registerAsUser()
        external
        onlyNotExistingUser(msg.sender)
        onlyNonPartner(msg.sender)
        onlyNonOwner(msg.sender)
    {
        _users.add(msg.sender);
    }

    function partnerRegistrationRequestExists(address partner) external view returns (bool) {
        return _partnerRegistrationRequests.contains(partner);
    }

    // Public functions
    /// @inheritdoc IWellnessHome
    function isPartner(address partner) public view returns (bool) {
        return _partners.contains(partner);
    }

    function isRevokedPartner(address partner) public view returns (bool) {
        return _revokedPartners.contains(partner);
    }

    /// @inheritdoc IWellnessHome
    function isUser(address user) public view returns (bool) {
        return _users.contains(user);
    }
}
