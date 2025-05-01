// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../src/AdvancedStaking.sol";
import "../src/IvoCoin.sol";

contract AdvancedStakingTest is Test {
  IvoCoin rewardToken;
  IvoCoin lpToken;
  AdvancedStaking staking;

  address owner = address(0xABCD);
  address user = address(0x1234);

  // Multi user transactions
  address user1 = address(0x1001);
  address user2 = address(0x1002);
  address user3 = address(0x1003);

  function setUp() public {
    vm.startPrank(owner);
    rewardToken = new IvoCoin(10000);
    lpToken = new IvoCoin(10000);
    staking = new AdvancedStaking(IERC20(address(rewardToken)));
    rewardToken.setMinter(address(staking));

    lpToken.mint(user, 1000);

    staking.addPool(IERC20(address(lpToken)), 1);

    lpToken.mint(user1, 1000);
    lpToken.mint(user2, 1000);
    lpToken.mint(user3, 1000);

    vm.stopPrank();
  }

  function testDepositAndWithdraw() public {
    vm.startPrank(user);

    lpToken.approve(address(staking), 1000);
    // Deposit 100 tokens into the first pool
    staking.deposit(0, 100);

    // Check that the user has staked 100 tokens
    (uint256 amount,) = staking.userStakes(0, user);
    assertEq(amount, 100);
    console.log("User staked amount: ", amount);

    // Advance 10 blocks
    vm.roll(block.number + 10);
    console.log("Current block number: ", block.number);

    staking.withdraw(0, 100);
    // Check that the user has withdrawn 100 tokens
    uint256 rewardBalance = rewardToken.balanceOf(user);
    // assertGt(rewardBalance, 0);
    console.log("Reward balance after withdrawal: ", rewardBalance);

    (uint256 finalAmount,) = staking.userStakes(0, user);
    assertEq(finalAmount, 0);

    vm.stopPrank();
  }

  function testMultiUserDepositsAndWithdrawsOverTime() public {
    // user1 deposits at block 1
    vm.startPrank(user1);
    lpToken.approve(address(staking), 1000);
    staking.deposit(0, 100);
    vm.stopPrank();

    vm.roll(block.number + 10); // block 11

    //
    /**
      User2 deposits at block 11
      User1 has already staked for 10 blocks = 10 rewards
      User2 will start staking at block 11
     */
    vm.startPrank(user2);
    lpToken.approve(address(staking), 1000);
    staking.deposit(0, 100);
    vm.stopPrank();

    vm.roll(block.number + 20); // block 31

    /**
      User3 deposits at block 31
      User1 has already staked for 30 blocks = 20 rewards
      User2 has staked for 20 blocks = 10 rewards
      User3 will start staking at block 31
     */
    vm.startPrank(user3);
    lpToken.approve(address(staking), 1000);
    staking.deposit(0, 100);
    vm.stopPrank();

    vm.roll(block.number + 69); // block 100 (in total we moved forward ~99 blocks)

    /**
      User1 has staked for 99 blocks = 42.77 rewards
      User2 has staked for 89 blocks = 32.77 rewards
      User3 has staked for 69 blocks = 22.77 rewards
    */

    // (uint256 user1Amount, uint256 user1Debt) = staking.userStakes(0, user1);
    // console.log(user1Amount, user1Debt);
    // staking.updatePool(0);
    // console.log(staking.pendingReward(0, user1));

    // Now withdraw all
    vm.startPrank(user1);
    staking.withdraw(0, 100);
    vm.stopPrank();

    vm.startPrank(user2);
    staking.withdraw(0, 100);
    vm.stopPrank();

    vm.startPrank(user3);
    staking.withdraw(0, 100);
    vm.stopPrank();

    // Check reward balances
    uint256 r1 = rewardToken.balanceOf(user1);
    uint256 r2 = rewardToken.balanceOf(user2);
    uint256 r3 = rewardToken.balanceOf(user3);

    console.log("User1 reward:", r1);
    console.log("User2 reward:", r2);
    console.log("User3 reward:", r3);

    // Validate they got rewards and sum is close to 99 (blocks)
    assertGt(r1, 0);
    assertGt(r2, 0);
    assertGt(r3, 0);
    assertApproxEqAbs(r1 + r2 + r3, 99, 1); // ±1 margin
  }
}
