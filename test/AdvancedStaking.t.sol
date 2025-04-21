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

  function setUp() public {
    vm.startPrank(owner);
    rewardToken = new IvoCoin(10000);
    lpToken = new IvoCoin(10000);
    staking = new AdvancedStaking(IERC20(address(rewardToken)));
    rewardToken.setMinter(address(staking));

    lpToken.mint(user, 1000);

    staking.addPool(IERC20(address(lpToken)), 1);
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
}
