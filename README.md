# UUPS Proxy Contract System

Production-grade upgradeable smart contract system implementing a TokenVault protocol using the Universal Upgradeable Proxy Standard (UUPS) pattern.

## Features

- **V1**: Basic deposit/withdrawal with fee mechanism
- **V2**: Yield generation and deposit pause controls
- **V3**: Withdrawal delays and emergency mechanisms

## Project Structure

```
contracts/
  ├── TokenVaultV1.sol
  ├── TokenVaultV2.sol
  ├── TokenVaultV3.sol
  └── mocks/
      └── MockERC20.sol

test/
  ├── TokenVaultV1.test.js
  ├── upgrade-v1-to-v2.test.js
  ├── upgrade-v2-to-v3.test.js
  └── security.test.js

scripts/
  ├── deploy-v1.js
  ├── upgrade-to-v2.js
  └── upgrade-to-v3.js
```

## Installation

```bash
npm install
```

## Running Tests

```bash
npm test
```

## Deployment

```bash
# Deploy V1
npm run deploy:v1

# Upgrade to V2
npm run upgrade:v2

# Upgrade to V3
npm run upgrade:v3
```

## Key Security Features

- Proper storage layout management with gaps
- Role-based access control (DEFAULT_ADMIN_ROLE, UPGRADER_ROLE, PAUSER_ROLE)
- Initializer security with reinitialization prevention
- UUPS upgradeable pattern
- Comprehensive test coverage

## Contract Functions

### TokenVaultV1
- `initialize(address _token, address _admin, uint256 _depositFee)`
- `deposit(uint256 amount)`
- `withdraw(uint256 amount)`
- `balanceOf(address user)`
- `totalDeposits()`
- `getDepositFee()`

### TokenVaultV2 (extends V1)
- `setYieldRate(uint256 _yieldRate)`
- `claimYield()`
- `pauseDeposits()`/`unpauseDeposits()`

### TokenVaultV3 (extends V2)
- `requestWithdrawal(uint256 amount)`
- `executeWithdrawal()`
- `emergencyWithdraw()`
- `setWithdrawalDelay(uint256 _delaySeconds)`

## License

MIT
