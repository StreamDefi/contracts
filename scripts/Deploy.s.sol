// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {TestToken} from "../src/TestToken.sol";
import {Vault} from "../src/lib/Vault.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        //
        // Deploy TestToken
        //

        // TestToken testToken = new TestToken(
        //     "Test USD", 
        //     "tUSD",
        //     6  // Same decimals as USDC/USDT
        // );
        // console2.log("Test Token deployed to:", address(testToken));

        // Mint some initial tokens for testing
        // testToken.mint(deployer, 1000000 * 10**6); // Mint 1M tokens

        //
        // Deploy StableWrapper
        //

        address lzEndpoint = 0x1a44076050125825900e736c501f859c50fE728c; // Eth LZ Endpoint
        StableWrapper wrapper = new StableWrapper(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            "xUSDC", 
            "xUSDC",
            6, // decimals
            deployer, // keeper
            lzEndpoint,
            deployer // delegate
        );

        console2.log("StableWrapper deployed to:", address(wrapper));

        //
        // Deploy StreamVault
        //
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 6,
            cap: 10000000 * 10**6, // 10M cap
            minimumSupply: 1 * 10**6 // 1 minimum
        });

        StreamVault vault = new StreamVault(
            "Stream Vault Token",
            "svToken",
            address(wrapper), // stableWrapper
            lzEndpoint,
            deployer, // delegate
            vaultParams
        );
        console2.log("StreamVault deployed to:", address(vault));

        //
        // Transfer StableWrapper ownership to vault
        //
        wrapper.setKeeper(address(vault));
        console2.log("StableWrapper keeper transferred to vault");

        vm.stopBroadcast();

        console2.log("\nDeployment Summary:");
        console2.log("-------------------");
        console2.log("StableWrapper:", address(wrapper));
        console2.log("StreamVault:", address(vault));
    }
}