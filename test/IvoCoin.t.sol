// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IvoCoin.sol";

contract IvoCoinTest is Test {
    IvoCoin token;
    uint constant INITIAL_SUPPLY = 1000;

    function setUp() public {
        token = new IvoCoin(INITIAL_SUPPLY); // 1000 tokens minted to deployer
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY * (10 ** token.decimals()));
    }

    function testTransfer() public {
        address recipient = address(0x123);
        token.transfer(recipient, 100 * (10 ** token.decimals()));
        assertEq(token.balanceOf(recipient), 100 * (10 ** token.decimals()));
    }

    function testMint() public {
        address recipient = address(0x123);
        token.mint(recipient, 100 * (10 ** token.decimals()));
        assertEq(token.balanceOf(recipient), 100 * (10 ** token.decimals()));
    }

    function testBurn() public {
        token.burn(INITIAL_SUPPLY * (10 ** token.decimals()));
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testSetOwner() public {
        address newOwner = address(0x123);
        token.setOwner(newOwner);
        assertEq(token.owner(), newOwner);
    }

    function testSetMinter() public {
        address newMinter = address(0x123);
        token.setMinter(newMinter);
        assert(token.hasRole(token.MINTER_ROLE(), newMinter));
    }
}
