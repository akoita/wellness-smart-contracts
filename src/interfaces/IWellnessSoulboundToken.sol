// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IWellnessSoulboundToken is IERC721, IAccessControl {
    function mint(address to) external;
    function mintReward(address to, uint256 amount) external;
    function grantMinterRole(address minter) external;
    function revokeMinterRole(address minter) external;
}
