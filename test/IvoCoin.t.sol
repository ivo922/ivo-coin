// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IvoCoin.sol";

contract IvoCoinTest is Test {
    IvoCoin token;

    function setUp() public {
        token = new IvoCoin(1000); // 1000 tokens minted to deployer
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000 * 10 ** token.decimals());
    }

    function testTransfer() public {
        address recipient = address(0x123);
        token.transfer(recipient, 100 * 10 ** token.decimals());
        assertEq(token.balanceOf(recipient), 100 * 10 ** token.decimals());
    }
}
