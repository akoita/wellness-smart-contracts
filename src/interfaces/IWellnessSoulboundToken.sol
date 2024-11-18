// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IWellnessSoulboundToken
 * @dev Interface for Wellness Soulbound Token contract.
 */
interface IWellnessSoulboundToken is IERC721 {
    /**
     * @notice Mints a new token to the specified address.
     * @param to The address to mint the token to.
     */
    function mint(address to) external;

    /**
     * @notice Mints a reward token to the specified address with a given amount.
     * @param to The address to mint the reward token to.
     * @param amount The amount of the reward token to mint.
     */
    function mintReward(address to, uint256 amount) external;

    /**
     * @notice Grants the minter role to the specified address.
     * @param minter The address to grant the minter role to.
     */
    function grantMinterRole(address minter) external;

    /**
     * @notice Revokes the minter role from the specified address.
     * @param minter The address to revoke the minter role from.
     */
    function revokeMinterRole(address minter) external;
}
