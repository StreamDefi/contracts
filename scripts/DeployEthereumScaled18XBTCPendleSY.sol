// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Script} from "forge-std/Script.sol";
// import {EthereumScaled18XBTCPendleSY} from "../src/EthereumScaled18XBTCPendleSY.sol";
// import {console2} from "forge-std/console2.sol";

// contract DeployEthereumScaled18XBTCPendleSYScript is Script {
//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);
        
//         EthereumScaled18XBTCPendleSY instance = new EthereumScaled18XBTCPendleSY(
//             "SY Staked Stream BTC scaled18", 
//             "SY-xBTC-scaled18",
//             0x992EC6A490A4B7f256bd59E63746951D98B29Be9
//         );
        
//         vm.stopBroadcast();

//         console2.log("EthereumScaled18XBTCPendleSY deployed to:", address(instance));
//     }
// }