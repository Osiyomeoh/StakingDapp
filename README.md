

# Staking Contracts and ERC20 Token

## Overview

This project contains three smart contracts:

1. **EtherStaking**: Allows users to stake Ether (ETH) and earn rewards.
2. **ERC20Staking**: Allows users to stake an ERC20 token and earn rewards.
3. **SamToken**: An ERC20 token that can be used for staking in the `ERC20Staking` contract.

## Features

- **Staking**: Users can stake either Ether or the `SamToken` ERC20 token.
- **Rewards**: Rewards are distributed based on the staking duration and amount staked.
- **Withdrawals**: Users can withdraw their staked assets after a lock period, claim rewards, or perform an emergency withdrawal.
- **Dynamic Reward Rate**: The reward rate increases as the total staked amount crosses certain thresholds.
- **Reentrancy Protection**: Both staking contracts are protected against reentrancy attacks.

## Smart Contract Details

### 1. `EtherStaking.sol`

- **Constructor**
  - Initializes the contract, setting the owner and the base reward rate.

- **initializeRewardPool**
  - Adds Ether to the reward pool, which will be distributed as rewards to stakers.

- **stake**
  - Allows users to stake Ether for a specified lock period.

- **withdraw**
  - Allows users to withdraw their staked Ether after the lock period and claim rewards.

- **claimRewards**
  - Allows users to claim their rewards without withdrawing their staked Ether.

- **emergencyWithdraw**
  - Allows users to withdraw their staked Ether immediately, bypassing the lock period, but forfeiting their rewards.

- **addRewards**
  - Allows the contract owner to add more rewards to the pool.

### 2. `ERC20Staking.sol`

- **Constructor**
  - Initializes the contract with the `SamToken` address and sets the owner.

- **initializeRewardPool**
  - Adds `SamToken` to the reward pool, which will be distributed as rewards to stakers.

- **stake**
  - Allows users to stake `SamToken` for a specified lock period.

- **withdraw**
  - Allows users to withdraw their staked `SamToken` after the lock period and claim rewards.

- **claimRewards**
  - Allows users to claim their rewards without withdrawing their staked `SamToken`.

- **emergencyWithdraw**
  - Allows users to withdraw their staked `SamToken` immediately, bypassing the lock period, but forfeiting their rewards.

- **addRewards**
  - Allows the contract owner to add more rewards to the pool.

### 3. `SamToken.sol`

- **Constructor**
  - Deploys the `SamToken` ERC20 token with a specified name and symbol. The owner can mint new tokens.

- **mint**
  - Allows the contract owner to mint new `SamToken`.

## Deployment

### Prerequisites

- Node.js
- Hardhat
- NPM or Yarn

### Install Dependencies

```bash
npm install
```

### Compile the Contracts

```bash
npx hardhat compile
```

### Deployment Scripts

#### EtherStaking Deployment

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingModule = buildModule("StakingModule", (m) => {
  const stakingContract = m.contract("EtherStaking");
  return { stakingContract };
});

export default StakingModule;
```

#### ERC20Staking and SamToken Deployment

```typescript
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ERC20StakingModule = buildModule("ERC20StakingModule", (m) => {
  const samToken = m.contract("SamToken", ["SamToken", "SAM"]);
  const stakingContract = m.contract("ERC20Staking", [samToken]);
  return { samToken, stakingContract };
});

export default ERC20StakingModule;
```

### Deploy the Contracts

To deploy the contracts to a network, use:

```bash
npx hardhat ignition deploy StakingModule --network <network_name>
npx hardhat ignition deploy ERC20StakingModule --network <network_name>
```

Replace `<network_name>` with the actual network you're deploying to, such as `localhost` or `sepolia`.

## Usage

### Staking Ether

```solidity
function stake(uint256 _lockPeriod) external payable;
```

- `msg.value` is the amount of Ether to stake.
- `_lockPeriod` is the time in seconds that the Ether will be locked.

### Staking SamToken

```solidity
function stake(uint256 _amount, uint256 _lockPeriod) external;
```

- `_amount` is the amount of `SamToken` to stake.
- `_lockPeriod` is the time in seconds that the tokens will be locked.

### Withdrawing Staked Assets

```solidity
function withdraw(uint256 _amount) external;
```

- `_amount` is the amount of Ether or `SamToken` to withdraw.

### Claiming Rewards

```solidity
function claimRewards() external;
```

### Emergency Withdrawal

```solidity
function emergencyWithdraw() external;
```

## Events

- **StakedSuccessful**
  - Emitted when a user successfully stakes Ether or `SamToken`.
- **WithdrawSuccessful**
  - Emitted when a user successfully withdraws Ether or `SamToken`.
- **RewardsClaimed**
  - Emitted when a user successfully claims rewards.
- **EmergencyWithdraw**
  - Emitted when a user performs an emergency withdrawal.

## Security Considerations

- **Reentrancy Protection**: Both staking contracts use a `nonReentrant` modifier to prevent reentrancy attacks.
- **Owner-Only Functions**: Functions that add rewards to the pool or initialize the reward pool are restricted to the contract owner.

## License

This project is licensed under the MIT License.

