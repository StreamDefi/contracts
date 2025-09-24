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

 // LZ Endpoints
    address constant ETH_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant HYPEREVM_ENDPOINT = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address constant LINEA_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant PLUME_ENDPOINT = 0xC1b15d3B262bEeC0e3565C11C9e0F6134BdaCB36;
    address constant KATANA_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant POLYGON_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant PLASMA_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;


    address constant ETH_SEND_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant ETH_RECEIVE_LIB = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address constant HYPEREVM_SEND_LIB = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address constant HYPEREVM_RECEIVE_LIB = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address constant LINEA_SEND_LIB = 0x32042142DD551b4EbE17B6FEd53131dd4b4eEa06;
    address constant LINEA_RECEIVE_LIB = 0xE22ED54177CE1148C557de74E4873619e6c6b205;
    address constant PLUME_SEND_LIB = 0xFe7C30860D01e28371D40434806F4A8fcDD3A098;
    address constant PLUME_RECEIVE_LIB = 0x5B19bd330A84c049b62D5B0FC2bA120217a18C1C;
    address constant KATANA_SEND_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant KATANA_RECEIVE_LIB = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address constant POLYGON_SEND_LIB = 0x6c26c61a97006888ea9E4FA36584c7df57Cd9dA3;
    address constant POLYGON_RECEIVE_LIB = 0x1322871e4ab09Bc7f5717189434f97bBD9546e95;
    address constant PLASMA_SEND_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant PLASMA_RECEIVE_LIB = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;



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
    address constant ETH_EURC_WRAPPED =
        0xDCFd98A5681722DF0d93fc11b9205f757576a427;
    address constant ETH_EURC_STAKED =
        0xc15697f61170Fc3Bb4e99Eb7913b4C7893F64F13;

    // HYPEREVM Contracts
    address constant HYPEREVM_BTC_WRAPPED =
        0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant HYPEREVM_BTC_STAKED =
        0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant HYPEREVM_USD_WRAPPED =
        0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant HYPEREVM_USD_STAKED =
        0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant HYPEREVM_ETH_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant HYPEREVM_ETH_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant HYPEREVM_EURC_WRAPPED =
        0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant HYPEREVM_EURC_STAKED =
        0x413bF752b33e76562dc876182141e2329716f250;

    // LINEA Contracts
    address constant LINEA_BTC_WRAPPED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant LINEA_BTC_STAKED =
        0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant LINEA_USD_WRAPPED =
        0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant LINEA_USD_STAKED =
        0x413bF752b33e76562dc876182141e2329716f250;
    address constant LINEA_ETH_WRAPPED =
        0x6F950EDd4f23bef6923DF96E6B3872eE60a982cd;
    address constant LINEA_ETH_STAKED =
        0x1e39413d695a9EEF1fB6dBe298D9ce0b7A9a065a;
    address constant LINEA_EURC_WRAPPED =
        0x308645E8f0F7345E3d60de29b2F74Fee92A387F6;
    address constant LINEA_EURC_STAKED =
        0xB4329eeE0cEa38d83817034621109C87a0a6eECb;

        
    // PLUME Contracts
    address constant PLUME_BTC_WRAPPED = 0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant PLUME_BTC_STAKED = 0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant PLUME_USD_WRAPPED = 0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant PLUME_USD_STAKED = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant PLUME_ETH_WRAPPED = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant PLUME_ETH_STAKED = 0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant PLUME_EURC_WRAPPED = 0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant PLUME_EURC_STAKED = 0x413bF752b33e76562dc876182141e2329716f250;

    //KATANA Contracts
    address constant KATANA_BTC_WRAPPED = 0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant KATANA_BTC_STAKED = 0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant KATANA_USD_WRAPPED = 0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant KATANA_USD_STAKED = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant KATANA_ETH_WRAPPED = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant KATANA_ETH_STAKED = 0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant KATANA_EURC_WRAPPED = 0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant KATANA_EURC_STAKED = 0x413bF752b33e76562dc876182141e2329716f250;

    //POLYGON Contracts
    address constant POLYGON_BTC_WRAPPED = 0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant POLYGON_BTC_STAKED = 0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant POLYGON_USD_WRAPPED = 0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant POLYGON_USD_STAKED = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant POLYGON_ETH_WRAPPED = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant POLYGON_ETH_STAKED = 0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant POLYGON_EURC_WRAPPED = 0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant POLYGON_EURC_STAKED = 0x413bF752b33e76562dc876182141e2329716f250;

    //PLASMA Contracts
    address constant PLASMA_BTC_WRAPPED = 0x212187708d01A63bcbE2F59553537de407a5621D;
    address constant PLASMA_BTC_STAKED = 0xa791082be08B890792c558F1292Ac4a2Dad21920;
    address constant PLASMA_USD_WRAPPED = 0x60E26068c264F13Ba87F67d33A9a3bd7763d5151;
    address constant PLASMA_USD_STAKED = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
    address constant PLASMA_ETH_WRAPPED = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    address constant PLASMA_ETH_STAKED = 0x94f9bB5c972285728DCee7EAece48BeC2fF341ce;
    address constant PLASMA_EURC_WRAPPED = 0xedcF5a7cf1228f5275d86449DDa30d29F36e40cF;
    address constant PLASMA_EURC_STAKED = 0x413bF752b33e76562dc876182141e2329716f250;
    
    

    // Chain IDs
    uint32 constant ETH_CHAIN_ID = 30101;
    uint32 constant HYPEREVM_CHAIN_ID = 30367;
    uint32 constant LINEA_CHAIN_ID = 30183;
    uint32 constant PLUME_CHAIN_ID = 30370;
    uint32 constant KATANA_CHAIN_ID = 30375;
    uint32 constant POLYGON_CHAIN_ID = 30109;
    uint32 constant PLASMA_CHAIN_ID = 30383;

    address constant LZ_ETH_DVN = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address constant NETHERMIND_ETH_DVN =
        0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;

    address constant LZ_HYPEREVM_DVN = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;
    address constant NETHERMIND_HYPEREVM_DVN =
        0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A;

    address constant LZ_LINEA_DVN = 0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480;
    address constant NETHERMIND_LINEA_DVN =
        0xDd7B5E1dB4AaFd5C8EC3b764eFB8ed265Aa5445B;
    
    address constant LZ_PLUME_DVN = 0x4208D6E27538189bB48E603D6123A94b8Abe0A0b;
    address constant NETHERMIND_PLUME_DVN =
        0x882a1EE8891c7d22310dedf032eF9653785532B8;

    address constant LZ_KATANA_DVN = 0x282b3386571f7f794450d5789911a9804FA346b4;
    address constant NETHERMIND_KATANA_DVN =
        0xaCDe1f22EEAb249d3ca6Ba8805C8fEe9f52a16e7;

    address constant LZ_POLYGON_DVN = 0x23DE2FE932d9043291f870324B74F820e11dc81A;
    address constant NETHERMIND_POLYGON_DVN =
        0x31F748a368a893Bdb5aBB67ec95F232507601A73;

    address constant LZ_PLASMA_DVN = 0x282b3386571f7f794450d5789911a9804FA346b4;
    address constant NETHERMIND_PLASMA_DVN =
        0xa51cE237FaFA3052D5d3308Df38A024724Bb1274;

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
            address wrappedEURC,
            address stakedEURC,
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
        console2.log("EURC Wrapped:", wrappedEURC);
        console2.log("EURC Staked:", stakedEURC);

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
            eid: PLASMA_CHAIN_ID,
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
        endpointManager.setConfig(wrappedEURC, sendLib, params);
        endpointManager.setConfig(stakedEURC, sendLib, params);

        // Set config for receive library
        console2.log("\nSetting Receive Library configs...");
        endpointManager.setConfig(wrappedBTC, receiveLib, params);
        endpointManager.setConfig(stakedBTC, receiveLib, params);
        endpointManager.setConfig(wrappedUSD, receiveLib, params);
        endpointManager.setConfig(stakedUSD, receiveLib, params);
        endpointManager.setConfig(wrappedETH, receiveLib, params);
        endpointManager.setConfig(stakedETH, receiveLib, params);
        endpointManager.setConfig(wrappedEURC, receiveLib, params);
        endpointManager.setConfig(stakedEURC, receiveLib, params);

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
            address wrappedEURC,
            address stakedEURC,
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
                ETH_EURC_WRAPPED,
                ETH_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("HYPEREVM"))) {
            dvns[1] = LZ_HYPEREVM_DVN;
            dvns[0] = NETHERMIND_HYPEREVM_DVN;
            return (
                HYPEREVM_ENDPOINT,
                HYPEREVM_SEND_LIB,
                HYPEREVM_RECEIVE_LIB,
                HYPEREVM_CHAIN_ID,
                HYPEREVM_BTC_WRAPPED,
                HYPEREVM_BTC_STAKED,
                HYPEREVM_USD_WRAPPED,
                HYPEREVM_USD_STAKED,
                HYPEREVM_ETH_WRAPPED,
                HYPEREVM_ETH_STAKED,
                HYPEREVM_EURC_WRAPPED,
                HYPEREVM_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("LINEA"))) {
            dvns[0] = LZ_LINEA_DVN;
            dvns[1] = NETHERMIND_LINEA_DVN;
            return (
                LINEA_ENDPOINT,
                LINEA_SEND_LIB,
                LINEA_RECEIVE_LIB,
                LINEA_CHAIN_ID,
                LINEA_BTC_WRAPPED,
                LINEA_BTC_STAKED,
                LINEA_USD_WRAPPED,
                LINEA_USD_STAKED,
                LINEA_ETH_WRAPPED,
                LINEA_ETH_STAKED,
                LINEA_EURC_WRAPPED,
                LINEA_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("PLUME"))) {
            dvns[0] = LZ_PLUME_DVN;
            dvns[1] = NETHERMIND_PLUME_DVN;
            return (
                PLUME_ENDPOINT,
                PLUME_SEND_LIB,
                PLUME_RECEIVE_LIB,
                PLUME_CHAIN_ID,
                PLUME_BTC_WRAPPED,
                PLUME_BTC_STAKED,
                PLUME_USD_WRAPPED,
                PLUME_USD_STAKED,
                PLUME_ETH_WRAPPED,
                PLUME_ETH_STAKED,
                PLUME_EURC_WRAPPED,
                PLUME_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("KATANA"))) {
            dvns[0] = LZ_KATANA_DVN;
            dvns[1] = NETHERMIND_KATANA_DVN;
            return (
                KATANA_ENDPOINT,
                KATANA_SEND_LIB,
                KATANA_RECEIVE_LIB,
                KATANA_CHAIN_ID,
                KATANA_BTC_WRAPPED,
                KATANA_BTC_STAKED,
                KATANA_USD_WRAPPED,
                KATANA_USD_STAKED,
                KATANA_ETH_WRAPPED,
                KATANA_ETH_STAKED,
                KATANA_EURC_WRAPPED,
                KATANA_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("POLYGON"))) {
            dvns[0] = LZ_POLYGON_DVN;
            dvns[1] = NETHERMIND_POLYGON_DVN;
            return (
                POLYGON_ENDPOINT,
                POLYGON_SEND_LIB,
                POLYGON_RECEIVE_LIB,
                POLYGON_CHAIN_ID,
                POLYGON_BTC_WRAPPED,
                POLYGON_BTC_STAKED,
                POLYGON_USD_WRAPPED,
                POLYGON_USD_STAKED,
                POLYGON_ETH_WRAPPED,
                POLYGON_ETH_STAKED,
                POLYGON_EURC_WRAPPED,
                POLYGON_EURC_STAKED,
                dvns
            );
        } else if (chainHash == keccak256(bytes("PLASMA"))) {
            dvns[0] = LZ_PLASMA_DVN;
            dvns[1] = NETHERMIND_PLASMA_DVN;
            return (
                PLASMA_ENDPOINT,
                PLASMA_SEND_LIB,
                PLASMA_RECEIVE_LIB,
                PLASMA_CHAIN_ID,
                PLASMA_BTC_WRAPPED,
                PLASMA_BTC_STAKED,
                PLASMA_USD_WRAPPED,
                PLASMA_USD_STAKED,
                PLASMA_ETH_WRAPPED,
                PLASMA_ETH_STAKED,
                PLASMA_EURC_WRAPPED,
                PLASMA_EURC_STAKED,
                dvns
            );
        } else revert("Invalid chain");

    }
}
