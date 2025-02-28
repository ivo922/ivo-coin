// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakingWithPenalty.sol";
import "../src/IvoCoin.sol";

contract StakingWithPenaltyTest is Test {
    StakingWithPenalty staking;
    IvoCoin token;
    address owner;
    address user1;
    address user2;

    uint256 initialSupply = 10000 ether;
    uint256 stakeAmount = 100 ether;
    uint256 rewardRate;
    uint256 lockTime;
    uint256 penaltyPercent;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new IvoCoin(initialSupply);
        staking = new StakingWithPenalty(address(token));
        rewardRate = staking.rewardRate();
        lockTime = staking.lockTime();
        penaltyPercent = staking.penaltyPercent();
        token.transfer(address(staking), 1000 ether); // Transfer some tokens to staking contract

        token.transfer(user1, stakeAmount);
        token.transfer(user2, stakeAmount);

        // Approve staking contract
        vm.prank(user1);
        token.approve(address(staking), stakeAmount);

        vm.prank(user2);
        token.approve(address(staking), stakeAmount);
    }

    function testUserCanStakeTokens() public {
        vm.prank(user1);
        staking.stake(stakeAmount);

        (uint256 amount, , ) = staking.stakes(user1);
        assertEq(amount, stakeAmount, "Stake amount should match");
    }

    function testRewardsAccumulateOverTime() public {
        vm.prank(user1);
        staking.stake(stakeAmount);

        // Move forward in time by 5 seconds
        vm.warp(block.timestamp + 5);

        uint256 reward = staking.getPendingReward(user1);
        assertApproxEqAbs(reward, rewardRate * 5, 1e18); // Allow small deviation
    }

    function testEarlyUnstakeAppliesPenalty() public {
        vm.prank(user1);
        staking.stake(stakeAmount);

        // Move time forward by 5 days (less than lock period)
        vm.warp(block.timestamp + 5 days);

        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        staking.unstake();

        uint256 balanceAfter = token.balanceOf(user1);
        uint256 expectedPenalty = (stakeAmount * penaltyPercent) / 100;
        assertApproxEqAbs(balanceAfter - balanceBefore, stakeAmount - expectedPenalty, 1e16);
    }

    function testUnstakingAfterLockPeriodHasNoPenalty() public {
        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        staking.stake(stakeAmount);

        // Move time forward beyond lock period (8 days)
        vm.warp(block.timestamp + 8 days);

        uint256 reward = staking.getPendingReward(user1);

        vm.prank(user1);
        staking.unstake();

        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter, balanceBefore + reward, "User should receive full amount");
    }

    function testOwnerCanUpdateLockTime() public {
        staking.setLockTime(10 days);
        assertEq(staking.lockTime(), 10 days, "Lock time should be updated");
    }

    function testOwnerCanUpdatePenaltyPercent() public {
        staking.setPenaltyPercent(30);
        assertEq(staking.penaltyPercent(), 30, "Penalty percent should be updated");
    }
}
