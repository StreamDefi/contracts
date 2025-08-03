// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {EthereumScaled18XBTCPendleSY} from "../src/EthereumScaled18XBTCPendleSY.sol";
import {console2} from "forge-std/console2.sol";

contract DeployEthereumScaled18XBTCPendleSYScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        EthereumScaled18XBTCPendleSY instance = new EthereumScaled18XBTCPendleSY(
            "SY-Scaled18-xBTC", 
            "SY-Scaled18-xBTC",
            
        );
        
        vm.stopBroadcast();

        console2.log("EthereumScaled18XBTCPendleSY deployed to:", address(instance));
    }
}