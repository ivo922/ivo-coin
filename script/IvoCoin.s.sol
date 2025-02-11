// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IvoCoin} from "../src/IvoCoin.sol";

contract IvoCoinScript is Script {
    IvoCoin public ivoCoin;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Load private key from env variable
        vm.startBroadcast(deployerPrivateKey); // Start broadcasting transactions
        IvoCoin token = new IvoCoin(1000000); // Deploy the contract with 1M tokens
        vm.stopBroadcast(); // Stop broadcasting
        console.log("Deployed IvoCoin at:", address(token)); // Print contract address
    }
}
