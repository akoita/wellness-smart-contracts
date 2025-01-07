# Wellness Reward Smart Contracts

The contracts are developed with the [Foundry](https://book.getfoundry.sh/) toolkit. The project was initialized with
the [Foundry Template](https://github.com/PaulRBerg/foundry-template).

## Installation

The development of the project requires functional installations of:

- [Foundry](https://book.getfoundry.sh/getting-started/installation/)
- [Node.js](https://nodejs.org/en/download/)

## Essential Commands

### Install Node.js dependencies

```bash
$ npm install
```

### Build smart contracts

```bash
$ forge build
```

### Clean

```bash
$ forge clean
```

### Tests execution

```bash
$ forge test
```

### Tests execution with coverage report

```bash
$ npm run test:coverage
```

### Tests execution with coverage report in HTML

```bash
$ npm run test:coverage:report
```

### Linting

```bash
$ npm run lint
```

### Formatting code

Formatting Solidity code with Forge:

```bash
$ forge fmt
```

Formatting JavaScript code with Prettier:

```bash
$ npm run prettier:write
```

## Deploying the contracts

### On anvil local network

Start anvil in one terminal:

```bash
$ anvil
```

Deploy the contracts from another terminal:

```bash
$ ./main.sh deploy --local
```

If the frontend project is located in the same directory as the contracts, i.e. `../wellness-frontend`, you can enable
the copy of the artifacts to the frontend project after the deployment with:

```bash
$ ./main.sh deploy --local --copy-artifacts
```

The artifacts will be copied to the `../wellness-frontend/public/foundry-artifacts` directory.

### On Base Sepolia network

First, export the required variables:

```bash
$ export API_KEY_BASESCAN=<your-api-key>
$ export PRIVATE_KEY=<your-private-key>
$ export PUBLIC_KEY=<your-account-address>
```

PRIVATE_KEY and PUBLIC_KEY are the private and public keys of the account you want to use to deploy the contracts.

API_KEY_BASESCAN is your [BaseScan API key](https://basescan.org/api), required to verify the contracts on BaseScan. You
can get an API key by creating an account on [BaseScan](https://basescan.org/).

Then, deploy the contracts:

```bash
$ ./main.sh deploy --testnet
```

This will deploy the contracts to the Base Sepolia network and verify them on BaseScan. The artifacts will be copied to
the `../testnet-artifacts` directory.

## Static Analysis

[Slither](https://github.com/crytic/slither) is used to improve the quality of the code. There is a dedicated job on the
CI pipeline to run the static analysis.

But you can also run it locally. For that you will need to install slither. If you have a functionnal python
environment, you can [install Slither](https://github.com/crytic/slither?tab=readme-ov-file#how-to-install) as follow:

```bash
$ pip install slither-analyzer
```

An to run the static analysis on the whole project just run:

```bash
$ slither .
```
