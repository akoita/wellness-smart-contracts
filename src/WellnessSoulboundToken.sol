// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { AdminRoleRequired, MinterRoleRequired } from "./commons/Errors.sol";
import { IWellnessSoulboundMetadata } from "./interfaces/IWellnessSoulboundMetadata.sol";
import { IWellnessSoulboundToken } from "./interfaces/IWellnessSoulboundToken.sol";
import { WellnessSoulboundTokenData } from "./types/DataTypes.sol";
import { Minted } from "./commons/events.sol";
import { SoulboundTokenNonTransferable } from "./commons/Errors.sol";

/// @title WellnessSoulboundToken
/// @author Wellness Protocol Team
/// @notice A non-transferable (soulbound) ERC721 token for wellness achievements
/// @dev Implements ERC721 with transfer restrictions and role-based access control
contract WellnessSoulboundToken is ERC721, AccessControlEnumerable, IWellnessSoulboundToken {
    // Type declarations
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables
    uint256 private _nextTokenId;
    IWellnessSoulboundMetadata public metadata;
    mapping(uint256 tokenId => WellnessSoulboundTokenData tokenData) public tokenIdToTokenData;

    // Modifiers
    /// @notice Restricts function access to accounts with minter role
    /// @dev Reverts if caller doesn't have MINTER_ROLE
    // slither-disable-next-line incorrect-modifier
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), MinterRoleRequired(msg.sender));
        _;
    }

    /// @notice Restricts function access to accounts with admin role
    /// @dev Reverts if caller doesn't have DEFAULT_ADMIN_ROLE
    // slither-disable-next-line incorrect-modifier
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), AdminRoleRequired(msg.sender));
        _;
    }

    /// @notice Initializes the contract with a default admin and token details
    /// @param defaultAdmin Address to be granted the admin role
    /// @param name_ Name of the token collection
    /// @param symbol_ Symbol of the token collection
    constructor(address defaultAdmin, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /// @notice Updates the metadata contract address
    /// @param metadata_ Address of the new metadata contract
    /// @dev Only callable by admin
    function setMetadata(IWellnessSoulboundMetadata metadata_) external onlyAdmin {
        metadata = metadata_;
    }

    /// @notice Mints a single token for a completed wellness challenge
    /// @param to Address to receive the token
    /// @param challengeCompletionId ID of the completed challenge
    /// @dev Emits a Minted event upon successful minting
    // slither-disable-start costly-loop
    function mint(address to, uint256 challengeCompletionId) public onlyMinter {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        tokenIdToTokenData[tokenId] = WellnessSoulboundTokenData({ challengeCompletionId: challengeCompletionId });
        emit Minted(tokenId, to, challengeCompletionId);
    }
    // slither-disable-end costly-loop

    /// @notice Mints multiple tokens as rewards for a single challenge completion
    /// @param to Address to receive the tokens
    /// @param amount Number of tokens to mint
    /// @param challengeCompletionId ID of the completed challenge
    /// @dev Calls mint() in a loop, may be gas intensive for large amounts
    function mintReward(address to, uint256 amount, uint256 challengeCompletionId) external onlyMinter {
        for (uint256 i = 0; i < amount; i++) {
            mint(to, challengeCompletionId);
        }
    }

    /// @notice Adds a new minter to the contract
    /// @param minter Address to be granted minting privileges
    /// @dev Only callable by admin
    function grantMinterRole(address minter) external onlyAdmin {
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Removes minting privileges from an address
    /// @param minter Address to have minting privileges revoked
    /// @dev Only callable by admin
    function revokeMinterRole(address minter) external onlyAdmin {
        _revokeRole(MINTER_ROLE, minter);
    }

    /// @notice Adds a new admin to the contract
    /// @param admin Address to be granted admin privileges
    /// @dev Only callable by existing admin
    function grantAdminRole(address admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Removes admin privileges from an address
    /// @param admin Address to have admin privileges revoked
    /// @dev Only callable by admin, be careful not to remove all admins
    function revokeAdminRole(address admin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Implementation of IERC165 interface detection
    /// @param interfaceId Interface identifier to check
    /// @return bool True if interface is supported
    /// @dev Adds support for IWellnessSoulboundToken interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || AccessControlEnumerable.supportsInterface(interfaceId)
            || interfaceId == type(IWellnessSoulboundToken).interfaceId;
    }

    /// @notice Internal hook to prevent token transfers
    /// @dev Allows minting (from = address(0)) but prevents all transfers
    /// @param to Destination address
    /// @param tokenId Token identifier
    /// @param auth Address that initiated the update
    /// @return address The previous owner of the token
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0)) {
            revert SoulboundTokenNonTransferable();
        }
        return super._update(to, tokenId, auth);
    }
}
