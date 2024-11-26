// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { PartnerSettings } from "../types/DataTypes.sol";

/**
 * @title IWellnessHome
 * @dev Interface for Wellness Home contract.
 */
interface IWellnessHome {
    /**
     * @notice Checks if an address is a registered partner.
     * @param partner The address to check.
     * @return bool True if the address is a registered partner, false otherwise.
     */
    function isPartner(address partner) external view returns (bool);

    /**
     * @notice Checks if an address is a registered user.
     * @param user The address to check.
     * @return bool True if the address is a registered user, false otherwise.
     */
    function isUser(address user) external view returns (bool);

    /**
     * @notice Gets the settings of a registered partner.
     * @param partner The address of the partner.
     * @return PartnerSettings The settings of the partner.
     */
    function getPartnerSettings(address partner) external view returns (PartnerSettings memory);
}
