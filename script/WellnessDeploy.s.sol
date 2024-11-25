//// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { BaseScript } from "./Base.s.sol";

import { WellnessHome } from "src/WellnessHome.sol";
import { ChallengeManager } from "src/ChallengeManager.sol";
import { PartnerChallengeCompletionValidationStrategy } from
    "src/modules/PartnerChallengeCompletionValidationStrategy.sol";
import { DefaultChallengeRewardStrategy } from "src/modules/DefaultChallengeRewardStrategy.sol";

contract WellnessDeploy is BaseScript {
    function run()
        public
        broadcast
        returns (
            WellnessHome wellnessHome,
            ChallengeManager challengeManager,
            PartnerChallengeCompletionValidationStrategy challengeCompletionValidationStrategy,
            DefaultChallengeRewardStrategy challengeRewardStrategy
        )
    {
        address deployer = msg.sender;

        // Deploy WellnessHome contract
        wellnessHome = new WellnessHome(deployer);

        // Deploy ChallengeManager contract
        challengeManager = new ChallengeManager(deployer, address(wellnessHome));

        // Deploy PartnerChallengeCompletionValidationStrategy contract
        challengeCompletionValidationStrategy = new PartnerChallengeCompletionValidationStrategy(deployer);
        // Set WellnessHome and ChallengeManager contracts in PartnerChallengeCompletionValidationStrategy
        challengeCompletionValidationStrategy.setWellnessHome(wellnessHome);
        challengeCompletionValidationStrategy.setChallengeManager(challengeManager);
        // Grant ChallengeCompletionValidatorRole to PartnerChallengeCompletionValidationStrategy
        challengeManager.grantChallengeCompletionValidatorRole(challengeCompletionValidationStrategy);

        // Deploy DefaultChallengeRewardStrategy contract
        challengeRewardStrategy = new DefaultChallengeRewardStrategy(deployer);
        // Set ChallengeManager contract in DefaultChallengeRewardStrategy
        challengeRewardStrategy.setChallengeManager(challengeManager);
        // Set challengeRewardStrategy contract in WellnessHome
        wellnessHome.setChallengeRewardStrategy(challengeRewardStrategy);
        // Grant ChallengeRewardStrategyRole to DefaultChallengeRewardStrategy
        challengeManager.grantChallengeRewardStrategyRole(challengeRewardStrategy);
    }
}
