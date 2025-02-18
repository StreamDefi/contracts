// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyOFT} from "../src/MyOFT.sol";
import {console2} from "forge-std/console2.sol";

contract DeployOFTScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy OFT for wrapped tokens (StableWrapper)
        address lzEndpoint = 0x1a44076050125825900e736c501f859c50fE728c; // Base LZ Endpoint
        MyOFT wrappedOFT = new MyOFT(
            "Stream USD", 
            "streamUSD",
            lzEndpoint,
            deployer, // delegate
            6 // decimals
        );
        console2.log("Wrapped OFT deployed to:", address(wrappedOFT));

        // Deploy OFT for staked tokens (StreamVault)
        MyOFT stakedOFT = new MyOFT(
            "Staked Stream USD",
            "xUSD",
            lzEndpoint,
            deployer, // delegate
            6 // decimals
        );
        console2.log("Staked OFT deployed to:", address(stakedOFT));

        vm.stopBroadcast();

        console2.log("\nDeployment Summary:");
        console2.log("-------------------");
        console2.log("Wrapped OFT:", address(wrappedOFT));
        console2.log("Staked OFT:", address(stakedOFT));
    }
}
