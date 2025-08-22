// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EthereumXETHPendleSY} from "../src/EthereumXETHPendleSY.sol";
import {console2} from "forge-std/console2.sol";

contract DeployEthereumXETHPendleSYScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        EthereumXETHPendleSY instance = new EthereumXETHPendleSY(
            "SY Staked Stream ETH", 
            "SY-xETH"
        );
        
        vm.stopBroadcast();

        console2.log("EthereumXETHPendleSY deployed to:", address(instance));
    }
}