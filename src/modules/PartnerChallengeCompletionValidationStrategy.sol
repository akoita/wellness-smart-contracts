// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IChallengeCompletionValidationStrategy } from "../interfaces/IChallengeCompletionValidationStrategy.sol";
import { IChallengeManager } from "../interfaces/IChallengeManager.sol";
import { IWellnessHome } from "../interfaces/IWellnessHome.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { InvalidPartner } from "../commons/Errors.sol";

contract PartnerChallengeCompletionValidationStrategy is Ownable, IChallengeCompletionValidationStrategy {
    IWellnessHome internal wellnessHome;
    IChallengeManager internal challengeManager;

    // modifiers
    modifier onlyPartner() {
        require(wellnessHome.isPartner(msg.sender), InvalidPartner(msg.sender));
        _;
    }

    constructor(address owner) Ownable(owner) { }

    function setWellnessHome(address wellnessHomeAddress) external onlyOwner {
        wellnessHome = IWellnessHome(wellnessHomeAddress);
    }

    function setChallengeManager(address challengeManagerAddress) external onlyOwner {
        challengeManager = IChallengeManager(challengeManagerAddress);
    }

    /// @inheritdoc IChallengeCompletionValidationStrategy
    function hasChallengeCompletionMetRequirements(uint256 challengeCompletionId) external view returns (bool) {
        return challengeManager.isChallengeCompletionApproved(challengeCompletionId);
    }

    function approoveChallengeCompletion(uint256 challengeCompletionId, bool approved) external onlyPartner {
        challengeManager.approoveChallengeCompletion(challengeCompletionId, approved);
    }
}
