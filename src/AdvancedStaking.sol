// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IvoCoin.sol";

contract AdvancedStaking is Ownable {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 rewardRate; // Reward tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward tokens distribution occurs.
        uint256 accRewardPerToken; // Accumulated reward tokens per share, times 1e12.
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    IERC20 public rewardToken;

    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => UserInfo)) public userStakes;
    uint256 public totalPools;


    constructor(
        IERC25 _rewardToken
    ) public Ownable(msg.sender) {
        rewardToken = _rewardToken;
    }

    /**
        * @dev Add a new LP to the pool. Can only be called by the owner.
        * @param _lpToken The address of the LP token contract.
        * @param _rewardRate The rate at which rewards are distributed.
        * @notice This function can only be called by the contract owner.
        * @notice This function is used to add a new pool for staking.
        * @notice The function updates the total number of pools.
    */
    function addPool(IERC20 _lpToken, uint256 _rewardRate) external onlyOwner {
        pools[totalPools] = Pool(
            {
                lpToken: _lpToken,
                rewardRate: _rewardRate,
                lastRewardBlock: block.number,
                accRewardPerToken: 0
            }
        );
        totalPools++;
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = pools[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalSupply = pool.lpToken.balanceOf(address(this));
        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 reward = multiplier * pool.rewardRate;
        pool.accRewardPerToken += (reward * 1e12) / totalSupply;
        pool.lastRewardBlock = block.number;
    }

    // ? Mint reward for newly staked tokens?
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userStakes[_pid][msg.sender];

        updatePool(_pid);

        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        uint256 pending = (user.amount * pool.accRewardPerToken) / 1e12 - user.rewardDebt;
        if (pending > 0) {
            rewardToken.mint(msg.sender, pending);
        }
        user.rewardDebt += (user.amount * pool.accRewardPerToken) / 1e12;
        user.amount += _amount;
    }

    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userStakes[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = (user.amount * pool.accRewardPerToken) / 1e12 - user.rewardDebt;

        if (pending > 0) {
            rewardToken.mint(msg.sender, pending);
        }

        user.amount += _amount;

        pool.lpToken.transfer(msg.sender, _amount);
        user.amount -= _amount;
        user.rewardDebt = (_amount * pool.accRewardPerToken) / 1e12;
    }
}
