# Wellness Reward Smart Contracts

The contracts are developed with the [Foundry](https://book.getfoundry.sh/) toolkit. The project was initialized with the [Foundry Template](https://github.com/PaulRBerg/foundry-template).


## Installation
The development of the project requires functional installations of:
- [Foundry](https://book.getfoundry.sh/getting-started/installation/)
- [Node.js](https://nodejs.org/en/download/)
  


## Essential Commands
### Build
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