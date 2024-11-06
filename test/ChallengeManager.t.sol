// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import { IWellnessHome } from "../src/interfaces/IWellnessHome.sol";
import { WellnessHome } from "../src/WellnessHome.sol";
import { ChallengeManager } from "../src/ChallengeManager.sol";
import { IChallengeCompletionValidationStrategy } from "../src/interfaces/IChallengeCompletionValidationStrategy.sol";
import { IChallengeRewardStrategy } from "../src/interfaces/IChallengeRewardStrategy.sol";
import { PartnerChallengeCompletionValidationStrategy } from
    "../src/modules/PartnerChallengeCompletionValidationStrategy.sol";
import { WellnessSoulboundToken } from "../src/WellnessSoulboundToken.sol";
import { DefaultChallengeRewardStrategy } from "../src/modules/DefaultChallengeRewardStrategy.sol";

contract ChallengeManagerTest is Test {
    address internal owner = address(this);
    ChallengeManager internal challengeManager;
    IWellnessHome internal wellnessHome;
    IChallengeCompletionValidationStrategy internal challengeCompletionValidationStrategy;
    IChallengeRewardStrategy internal challengeRewardStrategy;
    WellnessSoulboundToken internal soulboundToken;

    function setUp() public {
        wellnessHome = new WellnessHome(owner);
        challengeCompletionValidationStrategy = new PartnerChallengeCompletionValidationStrategy(owner);
        challengeRewardStrategy = new DefaultChallengeRewardStrategy(owner);
        challengeManager = new ChallengeManager(owner, address(wellnessHome));
    }
}
