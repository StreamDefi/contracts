// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EthereumXUSDPendleSY} from "../src/EthereumXUSDPendleSY.sol";
import {console2} from "forge-std/console2.sol";

contract DeployEthereumXUSDPendleSYScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        EthereumXUSDPendleSY instance = new EthereumXUSDPendleSY(
            "SY-xUSD", 
            "SY-xUSD"
        );
        
        vm.stopBroadcast();

        console2.log("EthereumXUSDPendleSY deployed to:", address(instance));
    }
}