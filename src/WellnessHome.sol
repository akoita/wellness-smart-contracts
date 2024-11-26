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

import { IChallengeRewardStrategy } from "./interfaces/IChallengeRewardStrategy.sol";

/// @title WellnessHome
/// @dev Manages partner and user registrations
contract WellnessHome is Ownable, IWellnessHome {
    using EnumerableSet for EnumerableSet.AddressSet;

    // State variables

    /// @custom:security unused-return
    EnumerableSet.AddressSet internal _partners;
    mapping(address partner => PartnerSettings partnerSettings) internal _partnersSettings;
    /// @custom:security unused-return
    EnumerableSet.AddressSet internal _partnerRegistrationRequests;
    /// @custom:security unused-return
    EnumerableSet.AddressSet internal _revokedPartners;
    /// @custom:security unused-return
    EnumerableSet.AddressSet internal _users;

    IChallengeRewardStrategy internal _challengeRewardStrategy;

    // Modifiers
    modifier onlyExistingPartner(address partner) {
        // slither-disable-next-line incorrect-modifier
        require(_partners.contains(partner), PartnerNotRegistered(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotExistingPartner(address partner) {
        require(!_partners.contains(partner), PartnerAlreadyRegistered(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyExistingPartnerRegistrationRequest(address partner) {
        require(_partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestNotFound(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotExistingPartnerRegistrationRequest(address partner) {
        require(!_partnerRegistrationRequests.contains(partner), PartnerRegistrationRequestAlreadySubmitted(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotRevokedPartner(address partner) {
        require(!_revokedPartners.contains(partner), PartnerIsRevoked(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNotExistingUser(address user) {
        require(!isUser(user), UserAlreadyRegistered(user));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNonUser(address partner) {
        require(!isUser(partner), ExistingUserWithThisAddress(partner));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNonPartner(address user) {
        require(!isPartner(user) && !isRevokedPartner(user), ExistingOrRevokedPartnerWithThisAddress(user));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyNonOwner(address account) {
        require(account != owner(), OwnerAddressForbidden(account));
        _;
    }

    // Constructor
    constructor(address initialOwner) Ownable(initialOwner) { }

    function setChallengeRewardStrategy(IChallengeRewardStrategy challengeRewardStrategy_) external onlyOwner {
        _challengeRewardStrategy = challengeRewardStrategy_;
    }

    // External functions
    /// @inheritdoc IWellnessHome
    function getPartnerSettings(address partner)
        external
        view
        onlyExistingPartner(partner)
        returns (PartnerSettings memory)
    {
        return _partnersSettings[partner];
    }

    // slither-disable-start unused-return
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
    // slither-disable-end unused-return

    // slither-disable-start unused-return
    function approvePartnerRegistration(address partner)
        external
        onlyOwner
        onlyExistingPartnerRegistrationRequest(partner)
    {
        _partnerRegistrationRequests.remove(partner);
        _partners.add(partner);

        PartnerSettings storage arguments = _partnersSettings[partner];

        // TODO: use the clone proxy to instantiate the soulbound token, much more gas efficient:
        // https://docs.openzeppelin.com/contracts/5.x/api/proxy#Clones
        // WellnessHome is the default admin of the soulbound token
        WellnessSoulboundToken soulboundToken =
            new WellnessSoulboundToken(address(this), arguments.soulboundTokenName, arguments.soulboundTokenSymbol);
        arguments.soulboundTokenAddress = address(soulboundToken);

        // Grant admin role to the owner on the soulbound token
        soulboundToken.grantAdminRole(owner());
        // Grant MinterRole to the challenge reward strategy on the soulbound token
        soulboundToken.grantMinterRole(address(_challengeRewardStrategy));
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
        // slither-disable-start unused-return
        _users.add(msg.sender);
        // slither-disable-end unused-return
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
