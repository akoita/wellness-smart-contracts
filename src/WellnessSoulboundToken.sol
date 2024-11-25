// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { AdminRoleRequired, MinterRoleRequired } from "./commons/Errors.sol";
import { IWellnessSoulboundMetadata } from "./interfaces/IWellnessSoulboundMetadata.sol";
import { IWellnessSoulboundToken } from "./interfaces/IWellnessSoulboundToken.sol";

/// @title WellnessSoulboundToken
/// @dev ERC721 token with soulbound properties and access control
contract WellnessSoulboundToken is ERC721, ERC721Burnable, AccessControlEnumerable, IWellnessSoulboundToken {
    // Type declarations
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables
    uint256 private _nextTokenId;
    IWellnessSoulboundMetadata public metadata;

    // Modifiers

    // slither-disable-next-line incorrect-modifier
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), MinterRoleRequired(msg.sender));
        _;
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), AdminRoleRequired(msg.sender));
        _;
    }

    /// @notice Constructor to initialize the WellnessSoulboundToken contract
    /// @param defaultAdmin The address of the default admin
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    constructor(address defaultAdmin, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    // External functions

    /// @notice Sets the metadata contract
    /// @param metadata_ The address of the metadata contract
    function setMetadata(IWellnessSoulboundMetadata metadata_) external onlyAdmin {
        metadata = metadata_;
    }

    /// @notice Mints a new token to the specified address
    /// @param to The address to mint the token to
    function mint(address to) public onlyMinter {
        uint256 tokenId = _nextTokenId;
        // slither-disable-next-line costly-loop
        _nextTokenId++;
        _safeMint(to, tokenId);
    }

    /// @notice Mints multiple tokens as a reward to the specified address
    /// @param to The address to mint the tokens to
    /// @param amount The number of tokens to mint
    function mintReward(address to, uint256 amount) external onlyMinter {
        for (uint256 i = 0; i < amount; i++) {
            mint(to);
        }
    }

    /// @notice Grants the minter role to an address
    /// @param minter The address to grant the minter role
    function grantMinterRole(address minter) external onlyAdmin {
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Revokes the minter role from an address
    /// @param minter The address to revoke the minter role
    function revokeMinterRole(address minter) external onlyAdmin {
        _revokeRole(MINTER_ROLE, minter);
    }

    /// @notice Grants the admin role to an address
    /// @param admin The address to grant the admin role
    function grantAdminRole(address admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Revokes the admin role from an address
    /// @param admin The address to revoke the admin role
    function revokeAdminRole(address admin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // Public functions
    /// @notice Checks if the contract supports a given interface
    /// @param interfaceId The interface identifier
    /// @return True if the interface is supported, false otherwise
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
