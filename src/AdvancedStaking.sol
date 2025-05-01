// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IvoCoin.sol";

using SafeERC20 for IERC20;


interface IMintToken {
    function mint(address to, uint256 amount) external;
}

contract AdvancedStaking is Ownable, ReentrancyGuard {
    struct PoolInfo {
        IERC20 stakingToken; // Address of LP token contract.
        uint256 rewardRate; // Reward tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that reward tokens distribution occurs.
        uint256 accRewardPerToken; // Accumulated reward tokens per share, times 1e12.
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    IERC20 public rewardToken;

    mapping(uint256 => PoolInfo) public pools;
    mapping(uint256 => mapping(address => UserInfo)) public userStakes;
    uint256 public totalPools;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(uint256 indexed pid, address stakingToken, uint256 rewardRate);

    constructor(IERC20 _rewardToken) Ownable(msg.sender) {
        rewardToken = _rewardToken;
    }

    /**
        * @dev Add a new LP to the pool. Can only be called by the owner.
        * @param _stakingToken The address of the LP token contract.
        * @param _rewardRate The rate at which rewards are distributed.
        * @notice This function can only be called by the contract owner.
        * @notice This function is used to add a new pool for staking.
        * @notice The function updates the total number of pools.
    */
    function addPool(IERC20 _stakingToken, uint256 _rewardRate) external onlyOwner {
        pools[totalPools] = PoolInfo(
            {
                stakingToken: _stakingToken,
                rewardRate: _rewardRate,
                lastRewardBlock: block.number,
                accRewardPerToken: 0
            }
        );
        totalPools++;
        emit PoolAdded(totalPools - 1, address(_stakingToken), _rewardRate);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = pools[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalSupply = pool.stakingToken.balanceOf(address(this));
        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 reward = multiplier * pool.rewardRate;

        pool.lastRewardBlock = block.number;

        if (totalSupply == 0) {
            return;
        }

        pool.accRewardPerToken += (reward * 1e12) / totalSupply;
    }

    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userStakes[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            withdrawReward(_pid);
        }
        pool.stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerToken) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userStakes[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        withdrawReward(_pid);
        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerToken) / 1e12;
        pool.stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }
    function withdrawReward(uint256 _pid) private {
        uint256 pending = pendingReward(_pid, msg.sender);
        if (pending > 0) {
            IMintToken(address(rewardToken)).mint(msg.sender, pending);
        }
    }

    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = pools[_pid];
        UserInfo memory user = userStakes[_pid][_user];

        return (user.amount * pool.accRewardPerToken) / 1e12 - user.rewardDebt;
    }
}

// ----------------------------------

contract RewardToken is IvoCoin {
    constructor(uint256 initialSupply) IvoCoin(initialSupply) {}
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }
}

contract StakingToken is IvoCoin {
    constructor(uint256 initialSupply) IvoCoin(initialSupply) {}
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
  }
