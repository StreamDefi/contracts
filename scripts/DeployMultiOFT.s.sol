// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyOFT} from "../src/MyOFT.sol";
import {console2} from "forge-std/console2.sol";

contract DeployMultiOFTScript is Script {
    // Structure to store deployment results
    struct DeploymentResult {
        string rpcUrl;
        address wrappedBTC;
        address stakedBTC;
        address wrappedUSDC;
        address stakedUSDC;
        address wrappedETH;
        address stakedETH;
    }

    function run() public {
        // Load deployer private key and API key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        string memory arbitrumEtherscanKey = vm.envString(
            "ARBITRUM_ETHERSCAN_KEY"
        );
        string memory avalancheEtherscanKey = vm.envString(
            "AVAX_ETHERSCAN_KEY"
        );
        string memory bscEtherscanKey = vm.envString("BNB_ETHERSCAN_KEY");
        string memory berachainEtherscanKey = vm.envString(
            "BERACHAIN_ETHERSCAN_KEY"
        );
        string memory optimismEtherscanKey = vm.envString(
            "OPTIMISM_ETHERSCAN_KEY"
        );
        // Get RPC URLs from .env
        string[] memory rpcUrls = new string[](5);
        rpcUrls[0] = vm.envString("AVAX_RPC_URL");
        rpcUrls[1] = vm.envString("BSC_RPC_URL");
        rpcUrls[2] = vm.envString("ARBITRUM_RPC_URL");
        rpcUrls[3] = vm.envString("BERACHAIN_RPC_URL");
        rpcUrls[4] = vm.envString("OPTIMISM_RPC_URL");

        string[] memory etherscanKeys = new string[](5);
        etherscanKeys[0] = avalancheEtherscanKey;
        etherscanKeys[1] = bscEtherscanKey;
        etherscanKeys[2] = arbitrumEtherscanKey;
        etherscanKeys[3] = berachainEtherscanKey;
        etherscanKeys[4] = optimismEtherscanKey;

        // Block explorer API URLs
        string[] memory verifyUrls = new string[](5);
        verifyUrls[0] = "https://api.snowtrace.io/api"; // AVAX
        verifyUrls[1] = "https://api.bscscan.com/api"; // BSC
        verifyUrls[2] = "https://api.arbiscan.io/api"; // Arbitrum
        verifyUrls[3] = "https://api.beratrail.io/api"; // Berachain
        verifyUrls[4] = "https://api-optimistic.etherscan.io/api"; // Optimism

        // LayerZero endpoints for each chain
        address[] memory lzEndpoints = new address[](5);
        lzEndpoints[0] = 0x1a44076050125825900e736c501f859c50fE728c; // AVAX
        lzEndpoints[1] = 0x1a44076050125825900e736c501f859c50fE728c; // BSC
        lzEndpoints[2] = 0x1a44076050125825900e736c501f859c50fE728c; // ARB
        lzEndpoints[3] = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B; // BERA
        lzEndpoints[4] = 0x1a44076050125825900e736c501f859c50fE728c; // OP

        // Array to store deployment results
        DeploymentResult[] memory deployments = new DeploymentResult[](
            rpcUrls.length
        );

        // Deploy on each chain
        for (uint256 i = 0; i < rpcUrls.length; i++) {
            // Create a fork for the current chain
            uint256 forkId = vm.createSelectFork(rpcUrls[i]);

            console2.log("\nDeploying to RPC URL:", rpcUrls[i]);
            console2.log("Fork ID:", forkId);

            vm.startBroadcast(deployerPrivateKey);

            // Deploy BTC OFTs
            MyOFT wrappedBTC = new MyOFT(
                "Stream BTC",
                "streamBTC",
                lzEndpoints[i],
                deployer,
                8
            );
            MyOFT stakedBTC = new MyOFT(
                "Staked Stream BTC",
                "xBTC",
                lzEndpoints[i],
                deployer,
                8
            );

            // Deploy USDC OFTs
            MyOFT wrappedUSDC = new MyOFT(
                "Stream USD",
                "streamUSD",
                lzEndpoints[i],
                deployer,
                6
            );
            MyOFT stakedUSDC = new MyOFT(
                "Staked Stream USD",
                "xUSD",
                lzEndpoints[i],
                deployer,
                6
            );

            // Deploy ETH OFTs
            MyOFT wrappedETH = new MyOFT(
                "Stream ETH",
                "streamETH",
                lzEndpoints[i],
                deployer,
                18
            );
            MyOFT stakedETH = new MyOFT(
                "Staked Stream ETH",
                "xETH",
                lzEndpoints[i],
                deployer,
                18
            );

            vm.stopBroadcast();

            // Verify contracts
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(wrappedBTC),
                "Stream BTC",
                "streamBTC",
                lzEndpoints[i],
                deployer,
                8
            );
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(stakedBTC),
                "Staked Stream BTC",
                "xBTC",
                lzEndpoints[i],
                deployer,
                8
            );
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(wrappedUSDC),
                "Stream USD",
                "streamUSD",
                lzEndpoints[i],
                deployer,
                6
            );
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(stakedUSDC),
                "Staked Stream USD",
                "xUSD",
                lzEndpoints[i],
                deployer,
                6
            );
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(wrappedETH),
                "Stream ETH",
                "streamETH",
                lzEndpoints[i],
                deployer,
                18
            );
            verifyContract(
                verifyUrls[i],
                etherscanKeys[i],
                address(stakedETH),
                "Staked Stream ETH",
                "xETH",
                lzEndpoints[i],
                deployer,
                18
            );

            console2.log("\nDeployments for RPC:", rpcUrls[i]);
            console2.log("BTC Wrapped:", address(wrappedBTC));
            console2.log("BTC Staked:", address(stakedBTC));
            console2.log("USDC Wrapped:", address(wrappedUSDC));
            console2.log("USDC Staked:", address(stakedUSDC));
            console2.log("ETH Wrapped:", address(wrappedETH));
            console2.log("ETH Staked:", address(stakedETH));

            // Store deployment results
            deployments[i] = DeploymentResult({
                rpcUrl: rpcUrls[i],
                wrappedBTC: address(wrappedBTC),
                stakedBTC: address(stakedBTC),
                wrappedUSDC: address(wrappedUSDC),
                stakedUSDC: address(stakedUSDC),
                wrappedETH: address(wrappedETH),
                stakedETH: address(stakedETH)
            });
        }

        // Print deployment summary
        console2.log("\nDeployment Summary:");
        console2.log("-------------------");
        for (uint256 i = 0; i < deployments.length; i++) {
            console2.log("\nRPC URL:", deployments[i].rpcUrl);
            console2.log("BTC Wrapped:", deployments[i].wrappedBTC);
            console2.log("BTC Staked:", deployments[i].stakedBTC);
            console2.log("USDC Wrapped:", deployments[i].wrappedUSDC);
            console2.log("USDC Staked:", deployments[i].stakedUSDC);
            console2.log("ETH Wrapped:", deployments[i].wrappedETH);
            console2.log("ETH Staked:", deployments[i].stakedETH);
        }
    }

    function verifyContract(
        string memory verifyUrl,
        string memory apiKey,
        address contractAddress,
        string memory name,
        string memory symbol,
        address lzEndpoint,
        address delegate,
        uint8 decimals
    ) internal {
        string[] memory inputs = new string[](10);
        inputs[0] = "forge";
        inputs[1] = "verify-contract";
        inputs[2] = vm.toString(contractAddress);
        inputs[3] = "MyOFT";
        inputs[4] = "--constructor-args";
        inputs[5] = string.concat(
            vm.toString(
                abi.encode(name, symbol, lzEndpoint, delegate, decimals)
            )
        );
        inputs[6] = "--verifier-url";
        inputs[7] = verifyUrl;
        inputs[8] = "--etherscan-api-key";
        inputs[9] = apiKey;

        try vm.ffi(inputs) returns (bytes memory) {
            console2.log(
                "Successfully verified contract at:",
                vm.toString(contractAddress)
            );
        } catch {
            console2.log(
                "Failed to verify contract at:",
                vm.toString(contractAddress)
            );
        }
    }
}
