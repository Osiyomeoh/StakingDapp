// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/// @title EtherStaking Contract
/// @notice This contract allows users to stake Ether, earn rewards, and withdraw their staked Ether after a lock period.
/// @dev The contract handles staking, reward distribution, and allows emergency withdrawal with reentrancy protection.
contract EtherStaking {
    address public owner;
    uint256 public rewardRate;
    uint256 public totalStaked;
    uint256 public totalRewardPool;
    uint256 public remainingRewards;
    uint256 constant MIN_LOCK_PERIOD = 5 minutes; // Minimum lock period of 5 minutes
    uint256 constant BASE_REWARD_RATE = 1e18;
    
    struct Staker {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 stakedAt;
        uint256 lockedTime;
    }

    mapping(address => Staker) public stakers;
    uint256 public lastRewardBlock;
    uint256 public accRewardPerToken;

    bool private entered;

    /// @dev Emitted when a user successfully stakes Ether.
    /// @param user The address of the user who staked Ether.
    /// @param amount The amount of Ether staked.
    event StakedSuccessful(address indexed user, uint256 amount);

    /// @dev Emitted when a user successfully withdraws Ether.
    /// @param user The address of the user who withdrew Ether.
    /// @param amount The amount of Ether withdrawn.
    event WithdrawSuccessful(address indexed user, uint256 amount);

    /// @dev Emitted when a user successfully claims rewards.
    /// @param user The address of the user who claimed rewards.
    /// @param amount The amount of rewards claimed.
    event RewardsClaimed(address indexed user, uint256 amount);

    /// @dev Emitted when a user performs an emergency withdrawal.
    /// @param user The address of the user who performed the emergency withdrawal.
    /// @param amount The amount of Ether withdrawn during the emergency.
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /// @dev Modifier to restrict function access to the contract owner.
    modifier onlyOwner {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    /// @dev Modifier to prevent reentrancy attacks.
    modifier nonReentrant() {
        require(!entered, "Reentrant call");
        entered = true;
        _;
        entered = false;
    }

    /// @notice Constructor initializes the contract.
    constructor() {
        owner = msg.sender;
        rewardRate = BASE_REWARD_RATE;
    }

    /// @notice Initialize the reward pool with a specific amount of Ether.
    /// @dev The function transfers the reward Ether to the contract.
    function initializeRewardPool() external payable onlyOwner {
        require(msg.value > 0, "Reward pool must be greater than zero");
        totalRewardPool += msg.value;
        remainingRewards += msg.value;
    }

    /// @notice Updates the reward rate based on the total staked amount.
    /// @dev This function adjusts the reward rate as the total staked amount crosses certain thresholds.
    function updateRewardRate() internal {
        if (totalStaked < 1e24) {
            rewardRate = BASE_REWARD_RATE;
        } else if (totalStaked < 5e24) {
            rewardRate = BASE_REWARD_RATE * 2;
        } else {
            rewardRate = BASE_REWARD_RATE * 3;
        }
    }

    /// @notice Updates the reward pool and accumulated rewards per token.
    /// @dev This function calculates the rewards for the stakers and updates the remaining rewards in the pool.
    function updatePool() internal {
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - lastRewardBlock;
        uint256 reward = multiplier * rewardRate;

        if (reward > remainingRewards) {
            reward = remainingRewards;
        }

        accRewardPerToken += (reward * 1e12) / totalStaked;
        remainingRewards -= reward;
        lastRewardBlock = block.number;
    }

    /// @notice Allows a user to stake Ether with a specific lock period.
    /// @param _lockPeriod The lock period (in seconds) during which the Ether cannot be withdrawn.
    function stake(uint256 _lockPeriod) external payable nonReentrant {
        require(msg.value > 0, "Stake amount must be greater than zero");
        require(_lockPeriod >= MIN_LOCK_PERIOD, "Minimum lock period of 5 minutes required");

        Staker storage thisStaker = stakers[msg.sender];
        updatePool();
        thisStaker.lockedTime = block.timestamp + _lockPeriod;

        if (thisStaker.stakedAmount > 0) {
            uint256 pending = (thisStaker.stakedAmount * accRewardPerToken / 1e12) - thisStaker.rewardDebt;
            if (pending > 0) {
                (bool success, ) = msg.sender.call{value: pending}("");
                require(success, "Reward transfer failed");
                emit RewardsClaimed(msg.sender, pending);
            }
        }

        thisStaker.stakedAmount += msg.value;
        thisStaker.rewardDebt = thisStaker.stakedAmount * accRewardPerToken / 1e12;
        thisStaker.stakedAt = block.timestamp;

        totalStaked += msg.value;
        updateRewardRate(); 

        emit StakedSuccessful(msg.sender, msg.value);
    }

    /// @notice Allows a user to withdraw a specified amount of staked Ether after the lock period.
    /// @param _amount The amount of Ether to withdraw.
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than zero");

        Staker storage thisStaker = stakers[msg.sender];
        require(thisStaker.stakedAmount >= _amount, "Withdraw: not enough staked");
        require(block.timestamp >= thisStaker.lockedTime, "Ether is locked");

        updatePool();

        uint256 pending = (thisStaker.stakedAmount * accRewardPerToken / 1e12) - thisStaker.rewardDebt;

        if (pending > 0) {
            (bool success, ) = msg.sender.call{value: pending}("");
            require(success, "Reward transfer failed");
            emit RewardsClaimed(msg.sender, pending);
        }

        thisStaker.stakedAmount -= _amount;
        thisStaker.rewardDebt = thisStaker.stakedAmount * accRewardPerToken / 1e12;

        totalStaked -= _amount;

        (bool withdrawSuccess, ) = msg.sender.call{value: _amount}("");
        require(withdrawSuccess, "Withdraw transfer failed");
        
        updateRewardRate();

        emit WithdrawSuccessful(msg.sender, _amount);
    }

    /// @notice Allows a user to claim their pending rewards without withdrawing their staked Ether.
    function claimRewards() external nonReentrant {
        Staker storage thisStaker = stakers[msg.sender];
        updatePool();

        uint256 pending = (thisStaker.stakedAmount * accRewardPerToken / 1e12) - thisStaker.rewardDebt;
        if (pending > 0) {
            (bool success, ) = msg.sender.call{value: pending}("");
            require(success, "Reward transfer failed");
            emit RewardsClaimed(msg.sender, pending);
        }

        thisStaker.rewardDebt = thisStaker.stakedAmount * accRewardPerToken / 1e12;
    }

    /// @notice Allows the owner to add more rewards to the pool.
    function addRewards() external payable onlyOwner {
        require(msg.value > 0, "Reward amount must be greater than zero");
        totalRewardPool += msg.value;
        remainingRewards += msg.value;
    }

    /// @notice Allows a user to perform an emergency withdrawal of their staked Ether, bypassing the lock period.
    function emergencyWithdraw() external nonReentrant {
        Staker storage thisStaker = stakers[msg.sender];
        uint256 stakedAmount = thisStaker.stakedAmount;

        require(stakedAmount > 0, "No staked amount found");

        updatePool();

        uint256 pending = (thisStaker.stakedAmount * accRewardPerToken / 1e12) - thisStaker.rewardDebt;

        thisStaker.stakedAmount = 0;
        thisStaker.rewardDebt = 0;

        totalStaked -= stakedAmount;

        if (pending > 0) {
            (bool success, ) = msg.sender.call{value: pending}("");
            require(success, "Reward transfer failed");
            emit RewardsClaimed(msg.sender, pending);
        }

        (bool withdrawSuccess, ) = msg.sender.call{value: stakedAmount}("");
        require(withdrawSuccess, "Emergency withdraw transfer failed");
        emit EmergencyWithdraw(msg.sender, stakedAmount);
    }

    /// @notice Returns the amount of Ether staked by the caller.
    /// @return The amount of Ether staked by the caller.
    function myStakedBalance() external view returns (uint256) {
        return stakers[msg.sender].stakedAmount;
    }

    /// @notice Returns the total amount of Ether staked in the contract.
    /// @return The total amount of Ether staked in the contract.
    function getStakedBalance() external view returns (uint256) {
        return totalStaked;
    }

    /// @notice Returns the total reward pool available in the contract.
    /// @return The total reward pool available in the contract.
    function rewardPool() external view returns (uint256) {
        return totalRewardPool;
    }
}
