// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MyOFT} from "../src/MyOFT.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract MultiSetEnforcedOptionsScript is Script {
    // AVAX Contracts
    address constant AVAX_BTC_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant AVAX_BTC_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant AVAX_USD_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant AVAX_USD_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant AVAX_ETH_WRAPPED =
        0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant AVAX_ETH_STAKED =
        0x413bF752b33e76562dc876182141e2329716f250;

    // BSC Contracts
    address constant BSC_BTC_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant BSC_BTC_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant BSC_USD_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant BSC_USD_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant BSC_ETH_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant BSC_ETH_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;

    // ARB Contracts
    address constant ARB_BTC_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant ARB_BTC_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant ARB_USD_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant ARB_USD_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant ARB_ETH_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant ARB_ETH_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;

    // BERA Contracts
    address constant BERA_BTC_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant BERA_BTC_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant BERA_USD_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant BERA_USD_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant BERA_ETH_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant BERA_ETH_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;

    // OPTIMISM Contracts
    address constant OPTIMISM_BTC_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant OPTIMISM_BTC_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant OPTIMISM_USD_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant OPTIMISM_USD_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant OPTIMISM_ETH_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant OPTIMISM_ETH_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;

    // BASE Contracts
    address constant BASE_BTC_WRAPPED =
        0x8A31D2D10f34aAF24A2c48713e213266bc01c68b;
    address constant BASE_BTC_STAKED =
        0x09Aed31D66903C8295129aebCBc45a32E9244a1f;
    address constant BASE_USD_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant BASE_USD_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant BASE_ETH_WRAPPED =
        0xc5332A5A8cBbB651A427F2cec9F779797311B839;
    address constant BASE_ETH_STAKED =
        0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926;

    // ETHEREUM Contracts
    address constant ETH_BTC_WRAPPED =
        0x05F47d7CbB0F3d7f988E442E8C1401685D2CAbE0;
    address constant ETH_BTC_STAKED =
        0x12fd502e2052CaFB41eccC5B596023d9978057d6;
    address constant ETH_USD_WRAPPED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant ETH_USD_STAKED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant ETH_ETH_WRAPPED =
        0xF70f54cEFdCd3C8f011865685FF49FB80A386a34;
    address constant ETH_ETH_STAKED =
        0x7E586fBaF3084C0be7aB5C82C04FfD7592723153;

    // Chain IDs
    uint32 constant AVAX_CHAIN_ID = 30106;
    uint32 constant BSC_CHAIN_ID = 30102;
    uint32 constant ARB_CHAIN_ID = 30110;
    uint32 constant BERA_CHAIN_ID = 30362;
    uint32 constant OP_CHAIN_ID = 30111;
    uint32 constant BASE_CHAIN_ID = 30184;
    uint32 constant ETH_CHAIN_ID = 30101;
    uint32 constant SONIC_CHAIN_ID = 30332;

    // SONIC Contracts
    address constant SONIC_BTC_WRAPPED =
        0xAA9bB583B25B9368AC711b57e7D5722444fb032d;
    address constant SONIC_BTC_STAKED =
        0xB88fF15ae5f82c791e637b27337909BcF8065270;
    address constant SONIC_USD_WRAPPED =
        0xc5332A5A8cBbB651A427F2cec9F779797311B839;
    address constant SONIC_USD_STAKED =
        0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926;
    address constant SONIC_ETH_WRAPPED =
        0x34F3D5120931CfAb0b3149858B8c17D51d68E0D6;
    address constant SONIC_ETH_STAKED =
        0x16af6b1315471Dc306D47e9CcEfEd6e5996285B6;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Create array of enforced options for each destination chain
        EnforcedOptionParam[] memory params = new EnforcedOptionParam[](1);
        uint256 paramIndex = 0;

        // Get current chain ID from environment variable
        string memory currentChain = vm.envString("CURRENT_CHAIN");
        uint32 currentChainId;
        (
            address wrappedBTC,
            address stakedBTC,
            address wrappedUSD,
            address stakedUSD,
            address wrappedETH,
            address stakedETH,
            uint32 chainId
        ) = getChainInfo(currentChain);
        currentChainId = chainId;

        console2.log("\nSetting enforced options for chain:", currentChain);
        console2.log("Chain ID:", currentChainId);

        // // Add all other chain IDs except current one
        // if (currentChainId != AVAX_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: AVAX_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != BSC_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: BSC_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != ARB_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: ARB_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != BERA_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: BERA_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != OP_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: OP_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != BASE_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: BASE_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        // if (currentChainId != ETH_CHAIN_ID) {
        //     params[paramIndex++] = EnforcedOptionParam({
        //         eid: ETH_CHAIN_ID,
        //         msgType: 1,
        //         options: hex"0003010011010000000000000000000000000000ea60"
        //     });
        // }
        if (currentChainId != SONIC_CHAIN_ID) {
            params[paramIndex++] = EnforcedOptionParam({
                eid: SONIC_CHAIN_ID,
                msgType: 1,
                options: hex"0003010011010000000000000000000000000000ea60"
            });
        }

        vm.startBroadcast(deployerPrivateKey);

        // Set enforced options for all contracts
        MyOFT(payable(wrappedBTC)).setEnforcedOptions(params);
        MyOFT(payable(stakedBTC)).setEnforcedOptions(params);
        MyOFT(payable(wrappedUSD)).setEnforcedOptions(params);
        MyOFT(payable(stakedUSD)).setEnforcedOptions(params);
        MyOFT(payable(wrappedETH)).setEnforcedOptions(params);
        MyOFT(payable(stakedETH)).setEnforcedOptions(params);

        console2.log("\nSet enforced options for contracts:");
        console2.log("BTC Wrapped:", wrappedBTC);
        console2.log("BTC Staked:", stakedBTC);
        console2.log("USD Wrapped:", wrappedUSD);
        console2.log("USD Staked:", stakedUSD);
        console2.log("ETH Wrapped:", wrappedETH);
        console2.log("ETH Staked:", stakedETH);

        vm.stopBroadcast();
    }

    function getChainInfo(
        string memory chain
    )
        internal
        pure
        returns (
            address wrappedBTC,
            address stakedBTC,
            address wrappedUSD,
            address stakedUSD,
            address wrappedETH,
            address stakedETH,
            uint32 chainId
        )
    {
        bytes32 chainHash = keccak256(bytes(chain));

        if (chainHash == keccak256("AVAX")) {
            return (
                AVAX_BTC_WRAPPED,
                AVAX_BTC_STAKED,
                AVAX_USD_WRAPPED,
                AVAX_USD_STAKED,
                AVAX_ETH_WRAPPED,
                AVAX_ETH_STAKED,
                AVAX_CHAIN_ID
            );
        } else if (chainHash == keccak256("BSC")) {
            return (
                BSC_BTC_WRAPPED,
                BSC_BTC_STAKED,
                BSC_USD_WRAPPED,
                BSC_USD_STAKED,
                BSC_ETH_WRAPPED,
                BSC_ETH_STAKED,
                BSC_CHAIN_ID
            );
        } else if (chainHash == keccak256("ARB")) {
            return (
                ARB_BTC_WRAPPED,
                ARB_BTC_STAKED,
                ARB_USD_WRAPPED,
                ARB_USD_STAKED,
                ARB_ETH_WRAPPED,
                ARB_ETH_STAKED,
                ARB_CHAIN_ID
            );
        } else if (chainHash == keccak256("BERA")) {
            return (
                BERA_BTC_WRAPPED,
                BERA_BTC_STAKED,
                BERA_USD_WRAPPED,
                BERA_USD_STAKED,
                BERA_ETH_WRAPPED,
                BERA_ETH_STAKED,
                BERA_CHAIN_ID
            );
        } else if (chainHash == keccak256("OPTIMISM")) {
            return (
                OPTIMISM_BTC_WRAPPED,
                OPTIMISM_BTC_STAKED,
                OPTIMISM_USD_WRAPPED,
                OPTIMISM_USD_STAKED,
                OPTIMISM_ETH_WRAPPED,
                OPTIMISM_ETH_STAKED,
                OP_CHAIN_ID
            );
        } else if (chainHash == keccak256("BASE")) {
            return (
                BASE_BTC_WRAPPED,
                BASE_BTC_STAKED,
                BASE_USD_WRAPPED,
                BASE_USD_STAKED,
                BASE_ETH_WRAPPED,
                BASE_ETH_STAKED,
                BASE_CHAIN_ID
            );
        } else if (chainHash == keccak256("ETH")) {
            return (
                ETH_BTC_WRAPPED,
                ETH_BTC_STAKED,
                ETH_USD_WRAPPED,
                ETH_USD_STAKED,
                ETH_ETH_WRAPPED,
                ETH_ETH_STAKED,
                ETH_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("SONIC"))) {
            return (
                SONIC_BTC_WRAPPED,
                SONIC_BTC_STAKED,
                SONIC_USD_WRAPPED,
                SONIC_USD_STAKED,
                SONIC_ETH_WRAPPED,
                SONIC_ETH_STAKED,
                SONIC_CHAIN_ID
            );
        }
        revert("Invalid chain");
    }
}
