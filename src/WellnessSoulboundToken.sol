// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { AdminRoleRequired } from "./commons/Errors.sol";

contract WellnessSoulboundToken is ERC721, ERC721Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;

    // Modifiers

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), AdminRoleRequired(msg.sender));
        _;
    }

    // constructor(address defaultAdmin, string memory name, string symbol) ERC721("WellnessSoulboundToken", "WST") {
    constructor(address defaultAdmin, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    function mint(address to) public onlyMinter {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function mintReward(address to, uint256 amount) public onlyMinter {
        for (uint256 i = 0; i < amount; i++) {
            mint(to);
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function grantMinterRole(address minter) public onlyAdmin {
        _grantRole(MINTER_ROLE, minter);
    }

    function revokeMinterRole(address minter) public onlyAdmin {
        _revokeRole(MINTER_ROLE, minter);
    }

    function grantAdminRole(address admin) public onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function revokeAdminRole(address admin) public onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
