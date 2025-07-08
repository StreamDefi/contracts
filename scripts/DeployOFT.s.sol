// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Script} from "forge-std/Script.sol";
// import {MyOFT} from "../src/MyOFT.sol";
// import {console2} from "forge-std/console2.sol";

// contract DeployOFTScript is Script {
//     function run() public {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         address deployer = vm.addr(deployerPrivateKey);

//         vm.startBroadcast(deployerPrivateKey);
//         address lzEndpoint = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
//         // MyOFT wrappedBTC = new MyOFT(
//         //     "Stream BTC",
//         //     "streamBTC",
//         //     lzEndpoint,
//         //     deployer,
//         //     8
//         // );
//         // MyOFT stakedBTC = new MyOFT(
//         //     "Staked Stream BTC",
//         //     "xBTC",
//         //     lzEndpoint,
//         //     deployer,
//         //     8
//         // );

//         // Deploy USDC OFTs
//         MyOFT wrappedUSDC = new MyOFT(
//             "Stream USD",
//             "streamUSD",
//             lzEndpoint,
//             deployer,
//             6
//         );
//         MyOFT stakedUSDC = new MyOFT(
//             "Staked Stream USD",
//             "xUSD",
//             lzEndpoint,
//             deployer,
//             6
//         );

//         // Deploy ETH OFTs
//         MyOFT wrappedETH = new MyOFT(
//             "Stream ETH",
//             "streamETH",
//             lzEndpoint,
//             deployer,
//             18
//         );
//         MyOFT stakedETH = new MyOFT(
//             "Staked Stream ETH",
//             "xETH",
//             lzEndpoint,
//             deployer,
//             18
//         );

//         vm.stopBroadcast();

//         console2.log("\nDeployment Summary:");
//         console2.log("-------------------");
//         // console2.log("\nBTC Vault:");
//         // console2.log("Wrapped BTC:", address(wrappedBTC));
//         // console2.log("Staked BTC:", address(stakedBTC));
//         console2.log("\nUSDC Vault:");
//         console2.log("Wrapped USD:", address(wrappedUSDC));
//         console2.log("Staked USD:", address(stakedUSDC));
//         console2.log("\nETH Vault:");
//         console2.log("Wrapped ETH:", address(wrappedETH));
//         console2.log("Staked ETH:", address(stakedETH));
//     }
// }
