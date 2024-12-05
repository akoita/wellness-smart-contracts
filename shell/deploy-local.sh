#! /bin/bash

set -e

set -x

export API_KEY_BASESCAN="YOUR_API_KEY_BASESCAN"

export COPY_ARTIFACTS_DESTINATION="$ROOT_DIR/../wellness-frontend/public/foundry-artifacts/"

FOUNDRY_DEFAULT_ACCOUNT="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

forge script script/WellnessDeploy.s.sol:WellnessDeploy --rpc-url http://localhost:8545 --broadcast --sender $FOUNDRY_DEFAULT_ACCOUNT

echo "Wellness contracts deployed to local network"

if $COPY_ARTIFACTS; then
    # Copy the artifacts for the Web client (frontend, etc.)
    rm -rf $COPY_ARTIFACTS_DESTINATION/*
    mkdir -p $COPY_ARTIFACTS_DESTINATION
    cp $ROOT_DIR/broadcast/WellnessDeploy.s.sol/31337/run-latest.json $COPY_ARTIFACTS_DESTINATION
    cp -r $ROOT_DIR/out/WellnessHome.sol $COPY_ARTIFACTS_DESTINATION
    cp -r $ROOT_DIR/out/ChallengeManager.sol $COPY_ARTIFACTS_DESTINATION
    cp -r $ROOT_DIR/out/WellnessSoulboundToken.sol $COPY_ARTIFACTS_DESTINATION
    cp -r $ROOT_DIR/out/DefaultChallengeRewardStrategy.sol $COPY_ARTIFACTS_DESTINATION
    cp -r $ROOT_DIR/out/PartnerChallengeCompletionValidationStrategy.sol $COPY_ARTIFACTS_DESTINATION

    echo "Artifacts copied to $COPY_ARTIFACTS_DESTINATION"
fi