// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IWellnessSoulboundToken } from "./IWellnessSoulboundToken.sol";

/**
 * @title IWellnessSoulboundMetadata
 * @dev Interface for retrieving metadata of Wellness Soulbound Tokens.
 */
interface IWellnessSoulboundMetadata {
    /**
     * @notice Retrieves the token URI for a given soulbound token and token ID.
     * @param soulboundToken The instance of the soulbound token.
     * @param tokenId The ID of the token.
     * @return string The token URI.
     */
    function tokenURI(IWellnessSoulboundToken soulboundToken, uint256 tokenId) external view returns (string memory);
}
