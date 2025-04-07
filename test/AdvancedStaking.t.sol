// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../src/AdvancedStaking.sol";
import "../src/IvoCoin.sol";

contract StakingWithPenaltyTest is Test {
  uint256 INITIAL_SUPPLY = 10000 ether;
  AdvancedStaking staking;
  IvoCoin token;
  address owner;
  address user1;
  address user2;

  function setUp() public {
    owner = address(this);
    user1 = address(0x1);
    user2 = address(0x2);

    token = new IvoCoin(initialSupply);
    staking = new AdvancedStaking(address(token));
    token.setMinter(address(staking));

    token.mint(user1, INITIAL_SUPPLY);
    token.mint(user2, INITIAL_SUPPLY);

    staking.addPool(address(token), 1000 ether);
  }
}
