// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMessageLibManager {
    function setSendLibrary(
        address _oapp,
        uint32 _dstEid,
        address _lib
    ) external;
}

contract MultiSetLibraryScript is Script {
    // LZ Endpoints
    address constant AVAX_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant BSC_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ARB_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant BERA_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant OPTIMISM_ENDPOINT =
        0x1a44076050125825900e736c501f859c50fE728c;
    address constant BASE_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ETH_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant SONIC_ENDPOINT =
        0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;

    // Send Libraries
    address constant AVAX_LIB = 0x197D1333DEA5Fe0D6600E9b396c7f1B1cFCc558a;
    address constant BSC_LIB = 0x9F8C645f2D0b2159767Bd6E0839DE4BE49e823DE;
    address constant ARB_LIB = 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;
    address constant BERA_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant OPTIMISM_LIB = 0x1322871e4ab09Bc7f5717189434f97bBD9546e95;
    address constant BASE_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant ETH_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant SONIC_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;

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

    // Chain IDs
    uint32 constant AVAX_CHAIN_ID = 30106;
    uint32 constant BSC_CHAIN_ID = 30102;
    uint32 constant ARB_CHAIN_ID = 30110;
    uint32 constant BERA_CHAIN_ID = 30362;
    uint32 constant OP_CHAIN_ID = 30111;
    uint32 constant BASE_CHAIN_ID = 30184;
    uint32 constant ETH_CHAIN_ID = 30101;
    uint32 constant SONIC_CHAIN_ID = 30332;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get current chain from environment variable
        string memory currentChain = vm.envString("CURRENT_CHAIN");
        (
            address wrappedBTC,
            address stakedBTC,
            address wrappedUSD,
            address stakedUSD,
            address wrappedETH,
            address stakedETH,
            address endpoint,
            uint32 chainId
        ) = getChainInfo(currentChain);

        console2.log("\nSetting library for chain:", currentChain);
        console2.log("Chain ID:", chainId);

        vm.startBroadcast(deployerPrivateKey);

        IMessageLibManager lzEndpoint = IMessageLibManager(endpoint);

        // Get current chain's library
        address currentLibrary;
        if (keccak256(bytes(currentChain)) == keccak256(bytes("AVAX"))) {
            currentLibrary = AVAX_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("BSC"))) {
            currentLibrary = BSC_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("ARB"))) {
            currentLibrary = ARB_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("BERA"))) {
            currentLibrary = BERA_LIB;
        } else if (
            keccak256(bytes(currentChain)) == keccak256(bytes("OPTIMISM"))
        ) {
            currentLibrary = OPTIMISM_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("BASE"))) {
            currentLibrary = BASE_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("ETH"))) {
            currentLibrary = ETH_LIB;
        } else if (
            keccak256(bytes(currentChain)) == keccak256(bytes("SONIC"))
        ) {
            currentLibrary = SONIC_LIB;
        }

        // // Set libraries for each contract for communication with other chains
        // if (chainId != AVAX_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         AVAX_CHAIN_ID,
        //         currentLibrary
        //     );
        // }
        // if (chainId != BSC_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BSC_CHAIN_ID,
        //         currentLibrary
        //     );
        // }
        // if (chainId != ARB_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         ARB_CHAIN_ID,
        //         currentLibrary
        //     );
        // }
        // if (chainId != BERA_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BERA_CHAIN_ID,
        //         currentLibrary
        //     );
        // }
        // if (chainId != OP_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         OP_CHAIN_ID,
        //         currentLibrary
        //     );
        // }

        // if (chainId != BASE_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BASE_CHAIN_ID,
        //         currentLibrary
        //     );
        // }
        // if (chainId != ETH_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         ETH_CHAIN_ID,
        //         currentLibrary
        //     );
        // }

        if (chainId != SONIC_CHAIN_ID) {
            setLibraryForChain(
                lzEndpoint,
                wrappedBTC,
                stakedBTC,
                wrappedUSD,
                stakedUSD,
                wrappedETH,
                stakedETH,
                SONIC_CHAIN_ID,
                currentLibrary
            );
        }

        vm.stopBroadcast();

        console2.log("\nSet library for contracts:");
        console2.log("BTC Wrapped:", wrappedBTC);
        console2.log("BTC Staked:", stakedBTC);
        console2.log("USD Wrapped:", wrappedUSD);
        console2.log("USD Staked:", stakedUSD);
        console2.log("ETH Wrapped:", wrappedETH);
        console2.log("ETH Staked:", stakedETH);
    }

    function setLibraryForChain(
        IMessageLibManager endpoint,
        address wrappedBTC,
        address stakedBTC,
        address wrappedUSD,
        address stakedUSD,
        address wrappedETH,
        address stakedETH,
        uint32 chainId,
        address lib
    ) internal {
        endpoint.setSendLibrary(wrappedBTC, chainId, lib);
        endpoint.setSendLibrary(stakedBTC, chainId, lib);
        endpoint.setSendLibrary(wrappedUSD, chainId, lib);
        endpoint.setSendLibrary(stakedUSD, chainId, lib);
        endpoint.setSendLibrary(wrappedETH, chainId, lib);
        endpoint.setSendLibrary(stakedETH, chainId, lib);
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
            address endpoint,
            uint32 chainId
        )
    {
        bytes32 chainHash = keccak256(bytes(chain));

        if (chainHash == keccak256(bytes("AVAX"))) {
            return (
                AVAX_BTC_WRAPPED,
                AVAX_BTC_STAKED,
                AVAX_USD_WRAPPED,
                AVAX_USD_STAKED,
                AVAX_ETH_WRAPPED,
                AVAX_ETH_STAKED,
                AVAX_ENDPOINT,
                AVAX_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("BSC"))) {
            return (
                BSC_BTC_WRAPPED,
                BSC_BTC_STAKED,
                BSC_USD_WRAPPED,
                BSC_USD_STAKED,
                BSC_ETH_WRAPPED,
                BSC_ETH_STAKED,
                BSC_ENDPOINT,
                BSC_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("ARB"))) {
            return (
                ARB_BTC_WRAPPED,
                ARB_BTC_STAKED,
                ARB_USD_WRAPPED,
                ARB_USD_STAKED,
                ARB_ETH_WRAPPED,
                ARB_ETH_STAKED,
                ARB_ENDPOINT,
                ARB_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("BERA"))) {
            return (
                BERA_BTC_WRAPPED,
                BERA_BTC_STAKED,
                BERA_USD_WRAPPED,
                BERA_USD_STAKED,
                BERA_ETH_WRAPPED,
                BERA_ETH_STAKED,
                BERA_ENDPOINT,
                BERA_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("OPTIMISM"))) {
            return (
                OPTIMISM_BTC_WRAPPED,
                OPTIMISM_BTC_STAKED,
                OPTIMISM_USD_WRAPPED,
                OPTIMISM_USD_STAKED,
                OPTIMISM_ETH_WRAPPED,
                OPTIMISM_ETH_STAKED,
                OPTIMISM_ENDPOINT,
                OP_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("BASE"))) {
            return (
                BASE_BTC_WRAPPED,
                BASE_BTC_STAKED,
                BASE_USD_WRAPPED,
                BASE_USD_STAKED,
                BASE_ETH_WRAPPED,
                BASE_ETH_STAKED,
                BASE_ENDPOINT,
                BASE_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("ETH"))) {
            return (
                ETH_BTC_WRAPPED,
                ETH_BTC_STAKED,
                ETH_USD_WRAPPED,
                ETH_USD_STAKED,
                ETH_ETH_WRAPPED,
                ETH_ETH_STAKED,
                ETH_ENDPOINT,
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
                SONIC_ENDPOINT,
                SONIC_CHAIN_ID
            );
        } else revert("Invalid chain");
    }
}
