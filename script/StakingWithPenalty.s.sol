// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingWithPenalty} from "../src/StakingWithPenalty.sol";

contract StakingWithPenaltyScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Load private key from env variable
        address memory ivoCoinAddress = vm.envAddress("IVOCOIN_ADDRESS");
        vm.startBroadcast(deployerPrivateKey); // Start broadcasting transactions
        StakingWithPenalty stakingContract = new StakingWithPenalty(ivoCoinAddress); // Deploy the contract with IvoCoin
        vm.stopBroadcast(); // Stop broadcasting
        console.log("Deployed StakingWithPenalty at:", address(token)); // Print contract address
    }
}
