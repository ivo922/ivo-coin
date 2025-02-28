// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingWithPenalty is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRate = 100; // Reward per token staked per second
    uint256 public lockTime = 7 days; // Minimum lock period
    uint256 public penaltyPercent = 20; // 20% penalty for early unstaking

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward, uint256 penalty);

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken); // Initialize staking token
    }

    /**
        * @dev Stake tokens to earn rewards
        * @param _amount Amount of tokens to stake
    */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");

        // Transfer tokens from user to contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate rewards before updating
        uint256 pendingReward = getPendingReward(msg.sender);
        StakeInfo storage stakeToUpdate = stakes[msg.sender];
        stakeToUpdate.rewardDebt += pendingReward;
        stakeToUpdate.amount += _amount;
        stakeToUpdate.timestamp = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    /**
        * @dev Get pending rewards for a user
        * @param _user User address
        * @return Pending rewards
    */
    function getPendingReward(address _user) public view returns (uint256) {
        StakeInfo storage stakeToCheck = stakes[_user];
        uint256 timeStaked = block.timestamp - stakeToCheck.timestamp;
        return (stakeToCheck.amount * rewardRate * timeStaked) / 1e18;
    }

    /**
        * @dev Unstake tokens and claim rewards
    */
    function unstake() external {
        StakeInfo storage stakeToUnstake = stakes[msg.sender];
        require(stakeToUnstake.amount > 0, "No tokens staked");

        uint256 reward = getPendingReward(msg.sender) + stakeToUnstake.rewardDebt;
        uint256 amount = stakeToUnstake.amount;
        uint256 penalty = 0;

        // Check if user is unstaking before lock period ends
        if (block.timestamp < stakeToUnstake.timestamp + lockTime) {
            penalty = (amount * penaltyPercent) / 100; // Apply penalty
            amount -= penalty; // Reduce amount by penalty
        }

        // Reset stake
        delete stakes[msg.sender];

        // Transfer tokens & rewards
        stakingToken.transfer(msg.sender, amount);
        if (reward > 0) {
            stakingToken.transfer(msg.sender, reward);
        }

        emit Unstaked(msg.sender, amount, reward, penalty);
    }

    /**
        * @dev Set lock time (Onwer only)
        * @param _lockTime Lock time in seconds
    */
    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    /**
        * @dev Set penalty percent (Onwer only)
        * @param _penaltyPercent Penalty percent
    */
    function setPenaltyPercent(uint256 _penaltyPercent) external onlyOwner {
        require(_penaltyPercent <= 100, "Invalid percentage");
        penaltyPercent = _penaltyPercent;
    }
}
