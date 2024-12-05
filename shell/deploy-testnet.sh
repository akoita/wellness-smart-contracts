#! /bin/bash

set -e
set -x

export ETH_FROM=$PUBLIC_KEY

forge script script/WellnessDeploy.s.sol:WellnessDeploy --rpc-url base_sepolia --broadcast --private-key $PRIVATE_KEY --sender $ETH_FROM --verify --verifier etherscan --etherscan-api-key ${API_KEY_BASESCAN}

echo "Wellness contracts deployed to Base Sepolia network"

# Copy the artifacts to the versioned folder
COPY_ARTIFACTS_DESTINATION="$ROOT_DIR/testnet-artifacts"

rm -rf $COPY_ARTIFACTS_DESTINATION/*
mkdir -p $COPY_ARTIFACTS_DESTINATION
cp $ROOT_DIR/broadcast/WellnessDeploy.s.sol/31337/run-latest.json $COPY_ARTIFACTS_DESTINATION
cp -r $ROOT_DIR/out/WellnessHome.sol $COPY_ARTIFACTS_DESTINATION
cp -r $ROOT_DIR/out/ChallengeManager.sol $COPY_ARTIFACTS_DESTINATION
cp -r $ROOT_DIR/out/WellnessSoulboundToken.sol $COPY_ARTIFACTS_DESTINATION
cp -r $ROOT_DIR/out/DefaultChallengeRewardStrategy.sol $COPY_ARTIFACTS_DESTINATION
cp -r $ROOT_DIR/out/PartnerChallengeCompletionValidationStrategy.sol $COPY_ARTIFACTS_DESTINATION

echo "Artifacts copied to $COPY_ARTIFACTS_DESTINATION"
