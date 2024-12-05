// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { PartnerSettings } from "../types/DataTypes.sol";

/**
 * @title IWellnessHome
 * @dev Interface for Wellness Home contract.
 */
interface IWellnessHome {
    /**
     * @notice Requests registration as a partner.
     * @param soulboundTokenName The name of the partner's soulbound token.
     * @param soulboundTokenSymbol The symbol of the partner's soulbound token.
     */
    function requestRegistrationAsPartner(
        string memory soulboundTokenName,
        string memory soulboundTokenSymbol
    )
        external
        payable;

    /**
     * @notice Approves a partner registration request.
     * @param partner The address of the partner to approve.
     */
    function approvePartnerRegistration(address partner) external;

    /**
     * @notice Revokes a partner's registration.
     * @param partner The address of the partner to revoke.
     */
    function revokePartnerRegistration(address partner) external;

    /**
     * @notice Registers the caller as a user.
     */
    function registerAsUser() external;

    /**
     * @notice Sets the partner registration fee.
     * @param fee The new fee amount.
     */
    function setPartnerRegistrationFee(uint256 fee) external;

    /**
     * @notice Gets the settings of a registered partner.
     * @param partner The address of the partner.
     * @return PartnerSettings The settings of the partner.
     */
    function getPartnerSettings(address partner) external view returns (PartnerSettings memory);

    /**
     * @notice Checks if a partner registration request exists.
     * @param partner The address to check.
     * @return bool True if a registration request exists for the partner, false otherwise.
     */
    function partnerRegistrationRequestExists(address partner) external view returns (bool);

    /**
     * @notice Checks if an address is a registered partner.
     * @param partner The address to check.
     * @return bool True if the address is a registered partner, false otherwise.
     */
    function isPartner(address partner) external view returns (bool);

    /**
     * @notice Checks if an address is a revoked partner.
     * @param partner The address to check.
     * @return bool True if the address is a revoked partner, false otherwise.
     */
    function isRevokedPartner(address partner) external view returns (bool);

    /**
     * @notice Checks if an address is a registered user.
     * @param user The address to check.
     * @return bool True if the address is a registered user, false otherwise.
     */
    function isUser(address user) external view returns (bool);
}
