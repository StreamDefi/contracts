// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMessageLibManager {
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }
    function setConfig(
        address _oapp,
        address _lib,
        SetConfigParam[] calldata _params
    ) external;
}

contract SetCustomConfigScript is Script {
    struct UlnConfig {
        uint64 confirmations;
        // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
        uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNThreshold; // (0, optionalDVNCount]
        address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
        address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
    }

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

    // Send Libraries
    address constant AVAX_SEND_LIB = 0x197D1333DEA5Fe0D6600E9b396c7f1B1cFCc558a;
    address constant BSC_SEND_LIB = 0x9F8C645f2D0b2159767Bd6E0839DE4BE49e823DE;
    address constant ARB_SEND_LIB = 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;
    address constant BERA_SEND_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant OPTIMISM_SEND_LIB =
        0x1322871e4ab09Bc7f5717189434f97bBD9546e95;
    address constant BASE_SEND_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant ETH_SEND_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant SONIC_SEND_LIB =
        0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;

    address constant AVAX_RECEIVE_LIB =
        0xbf3521d309642FA9B1c91A08609505BA09752c61; // To be filled in later
    address constant BSC_RECEIVE_LIB =
        0xB217266c3A98C8B2709Ee26836C98cf12f6cCEC1;
    address constant ARB_RECEIVE_LIB =
        0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6;
    address constant BERA_RECEIVE_LIB =
        0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address constant OPTIMISM_RECEIVE_LIB =
        0x3c4962Ff6258dcfCafD23a814237B7d6Eb712063;
    address constant BASE_RECEIVE_LIB =
        0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address constant ETH_RECEIVE_LIB =
        0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address constant SONIC_RECEIVE_LIB =
        0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;

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

    address constant LZ_ETH_DVN = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address constant NETHERMIND_ETH_DVN =
        0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;

    address constant LZ_SONIC_DVN = 0x282b3386571f7f794450d5789911a9804FA346b4;
    address constant NETHERMIND_SONIC_DVN =
        0x05AaEfDf9dB6E0f7d27FA3b6EE099EDB33dA029E;

    address constant LZ_BASE_DVN = 0x9e059a54699a285714207b43B055483E78FAac25;
    address constant NETHERMIND_BASE_DVN =
        0xcd37CA043f8479064e10635020c65FfC005d36f6;

    address constant LZ_OPTIMISM_DVN =
        0x6A02D83e8d433304bba74EF1c427913958187142;
    address constant NETHERMIND_OPTIMISM_DVN =
        0xa7b5189bcA84Cd304D8553977c7C614329750d99;

    address constant LZ_BERA_DVN = 0x282b3386571f7f794450d5789911a9804FA346b4;
    address constant NETHERMIND_BERA_DVN =
        0xDd7B5E1dB4AaFd5C8EC3b764eFB8ed265Aa5445B;

    address constant LZ_ARB_DVN = 0x2f55C492897526677C5B68fb199ea31E2c126416;
    address constant NETHERMIND_ARB_DVN =
        0xa7b5189bcA84Cd304D8553977c7C614329750d99;

    address constant LZ_BSC_DVN = 0xfD6865c841c2d64565562fCc7e05e619A30615f0;
    address constant NETHERMIND_BSC_DVN =
        0x31F748a368a893Bdb5aBB67ec95F232507601A73;

    address constant LZ_AVAX_DVN = 0x962F502A63F5FBeB44DC9ab932122648E8352959;
    address constant NETHERMIND_AVAX_DVN =
        0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;

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
        string memory currentChain = vm.envString("CURRENT_CHAIN");

        // Get endpoint and libraries for current chain
        (
            address endpoint,
            address sendLib,
            address receiveLib,
            uint32 chainId,
            address wrappedBTC,
            address stakedBTC,
            address wrappedUSD,
            address stakedUSD,
            address wrappedETH,
            address stakedETH,
            address[] memory chainDVNs
        ) = getChainInfo(currentChain);

        IMessageLibManager endpointManager = IMessageLibManager(endpoint);

        console2.log("\nSetting config for chain:", currentChain);
        console2.log("Endpoint:", endpoint);
        console2.log("Send Library:", sendLib);
        console2.log("Receive Library:", receiveLib);
        console2.log("Chain ID:", chainId);
        console2.log("\nContracts to configure:");
        console2.log("BTC Wrapped:", wrappedBTC);
        console2.log("BTC Staked:", stakedBTC);
        console2.log("USD Wrapped:", wrappedUSD);
        console2.log("USD Staked:", stakedUSD);
        console2.log("ETH Wrapped:", wrappedETH);
        console2.log("ETH Staked:", stakedETH);

        vm.startBroadcast(deployerPrivateKey);

        // Create ULN config for SONIC chain
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: chainDVNs,
            optionalDVNs: new address[](0)
        });

        // Create config params array
        IMessageLibManager.SetConfigParam[]
            memory params = new IMessageLibManager.SetConfigParam[](1);
        params[0] = IMessageLibManager.SetConfigParam({
            eid: AVAX_CHAIN_ID,
            configType: 2,
            config: abi.encode(ulnConfig)
        });

        // Set config for send library
        console2.log("\nSetting Send Library configs...");
        endpointManager.setConfig(wrappedBTC, sendLib, params);
        endpointManager.setConfig(stakedBTC, sendLib, params);
        endpointManager.setConfig(wrappedUSD, sendLib, params);
        endpointManager.setConfig(stakedUSD, sendLib, params);
        endpointManager.setConfig(wrappedETH, sendLib, params);
        endpointManager.setConfig(stakedETH, sendLib, params);

        // Set config for receive library
        console2.log("\nSetting Receive Library configs...");
        endpointManager.setConfig(wrappedBTC, receiveLib, params);
        endpointManager.setConfig(stakedBTC, receiveLib, params);
        endpointManager.setConfig(wrappedUSD, receiveLib, params);
        endpointManager.setConfig(stakedUSD, receiveLib, params);
        endpointManager.setConfig(wrappedETH, receiveLib, params);
        endpointManager.setConfig(stakedETH, receiveLib, params);

        vm.stopBroadcast();

        console2.log("\nConfig setup complete");
    }

    function getChainInfo(
        string memory chain
    )
        internal
        pure
        returns (
            address endpoint,
            address sendLib,
            address receiveLib,
            uint32 chainId,
            address wrappedBTC,
            address stakedBTC,
            address wrappedUSD,
            address stakedUSD,
            address wrappedETH,
            address stakedETH,
            address[] memory chainDVNs
        )
    {
        bytes32 chainHash = keccak256(bytes(chain));

        // Initialize DVN array
        address[] memory dvns = new address[](2);

        if (chainHash == keccak256(bytes("ETH"))) {
            dvns[0] = LZ_ETH_DVN;
            dvns[1] = NETHERMIND_ETH_DVN;
            return (
                ETH_ENDPOINT,
                ETH_SEND_LIB,
                ETH_RECEIVE_LIB,
                ETH_CHAIN_ID,
                ETH_BTC_WRAPPED,
                ETH_BTC_STAKED,
                ETH_USD_WRAPPED,
                ETH_USD_STAKED,
                ETH_ETH_WRAPPED,
                ETH_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("AVAX"))) {
            dvns[0] = LZ_AVAX_DVN;
            dvns[1] = NETHERMIND_AVAX_DVN;
            return (
                AVAX_ENDPOINT,
                AVAX_SEND_LIB,
                AVAX_RECEIVE_LIB,
                AVAX_CHAIN_ID,
                AVAX_BTC_WRAPPED,
                AVAX_BTC_STAKED,
                AVAX_USD_WRAPPED,
                AVAX_USD_STAKED,
                AVAX_ETH_WRAPPED,
                AVAX_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("BSC"))) {
            dvns[0] = LZ_BSC_DVN;
            dvns[1] = NETHERMIND_BSC_DVN;
            return (
                BSC_ENDPOINT,
                BSC_SEND_LIB,
                BSC_RECEIVE_LIB,
                BSC_CHAIN_ID,
                BSC_BTC_WRAPPED,
                BSC_BTC_STAKED,
                BSC_USD_WRAPPED,
                BSC_USD_STAKED,
                BSC_ETH_WRAPPED,
                BSC_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("ARB"))) {
            dvns[0] = LZ_ARB_DVN;
            dvns[1] = NETHERMIND_ARB_DVN;
            return (
                ARB_ENDPOINT,
                ARB_SEND_LIB,
                ARB_RECEIVE_LIB,
                ARB_CHAIN_ID,
                ARB_BTC_WRAPPED,
                ARB_BTC_STAKED,
                ARB_USD_WRAPPED,
                ARB_USD_STAKED,
                ARB_ETH_WRAPPED,
                ARB_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("BERA"))) {
            dvns[0] = LZ_BERA_DVN;
            dvns[1] = NETHERMIND_BERA_DVN;
            return (
                BERA_ENDPOINT,
                BERA_SEND_LIB,
                BERA_RECEIVE_LIB,
                BERA_CHAIN_ID,
                BERA_BTC_WRAPPED,
                BERA_BTC_STAKED,
                BERA_USD_WRAPPED,
                BERA_USD_STAKED,
                BERA_ETH_WRAPPED,
                BERA_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("OPTIMISM"))) {
            dvns[0] = LZ_OPTIMISM_DVN;
            dvns[1] = NETHERMIND_OPTIMISM_DVN;
            return (
                OPTIMISM_ENDPOINT,
                OPTIMISM_SEND_LIB,
                OPTIMISM_RECEIVE_LIB,
                OP_CHAIN_ID,
                OPTIMISM_BTC_WRAPPED,
                OPTIMISM_BTC_STAKED,
                OPTIMISM_USD_WRAPPED,
                OPTIMISM_USD_STAKED,
                OPTIMISM_ETH_WRAPPED,
                OPTIMISM_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("BASE"))) {
            dvns[0] = LZ_BASE_DVN;
            dvns[1] = NETHERMIND_BASE_DVN;
            return (
                BASE_ENDPOINT,
                BASE_SEND_LIB,
                BASE_RECEIVE_LIB,
                BASE_CHAIN_ID,
                BASE_BTC_WRAPPED,
                BASE_BTC_STAKED,
                BASE_USD_WRAPPED,
                BASE_USD_STAKED,
                BASE_ETH_WRAPPED,
                BASE_ETH_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("SONIC"))) {
            dvns[1] = LZ_SONIC_DVN;
            dvns[0] = NETHERMIND_SONIC_DVN;
            return (
                SONIC_ENDPOINT,
                SONIC_SEND_LIB,
                SONIC_RECEIVE_LIB,
                SONIC_CHAIN_ID,
                SONIC_BTC_WRAPPED,
                SONIC_BTC_STAKED,
                SONIC_USD_WRAPPED,
                SONIC_USD_STAKED,
                SONIC_ETH_WRAPPED,
                SONIC_ETH_STAKED,
                dvns
            );
        }

        revert("Invalid chain");
    }
}
