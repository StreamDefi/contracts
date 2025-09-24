// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyOFT} from "../src/MyOFT.sol";
import {console2} from "forge-std/console2.sol";

contract SetMultiPeersScript is Script {
  

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

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

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
            address wrappedEURC,
            address stakedEURC,
            uint32 chainId
        ) = getChainInfo(currentChain);

        console2.log("\nSetting peers for chain:", currentChain);
        console2.log("Chain ID:", chainId);

        vm.startBroadcast(deployerPrivateKey);

        // // Set peers for each contract for communication with other chains
        // if (chainId != AVAX_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         AVAX_CHAIN_ID,
        //         AVAX_BTC_WRAPPED,
        //         AVAX_BTC_STAKED,
        //         AVAX_USD_WRAPPED,
        //         AVAX_USD_STAKED,
        //         AVAX_ETH_WRAPPED,
        //         AVAX_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for AVAX chain");
        // }

        // if (chainId != BSC_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BSC_CHAIN_ID,
        //         BSC_BTC_WRAPPED,
        //         BSC_BTC_STAKED,
        //         BSC_USD_WRAPPED,
        //         BSC_USD_STAKED,
        //         BSC_ETH_WRAPPED,
        //         BSC_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for BSC chain");
        // }

        // if (chainId != ARB_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         ARB_CHAIN_ID,
        //         ARB_BTC_WRAPPED,
        //         ARB_BTC_STAKED,
        //         ARB_USD_WRAPPED,
        //         ARB_USD_STAKED,
        //         ARB_ETH_WRAPPED,
        //         ARB_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for ARB chain");
        // }

        // if (chainId != BERA_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BERA_CHAIN_ID,
        //         BERA_BTC_WRAPPED,
        //         BERA_BTC_STAKED,
        //         BERA_USD_WRAPPED,
        //         BERA_USD_STAKED,
        //         BERA_ETH_WRAPPED,
        //         BERA_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for BERA chain");
        // }

        // if (chainId != OP_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         OP_CHAIN_ID,
        //         OPTIMISM_BTC_WRAPPED,
        //         OPTIMISM_BTC_STAKED,
        //         OPTIMISM_USD_WRAPPED,
        //         OPTIMISM_USD_STAKED,
        //         OPTIMISM_ETH_WRAPPED,
        //         OPTIMISM_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for OPTIMISM chain");
        // }

        // if (chainId != BASE_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         BASE_CHAIN_ID,
        //         BASE_BTC_WRAPPED,
        //         BASE_BTC_STAKED,
        //         BASE_USD_WRAPPED,
        //         BASE_USD_STAKED,
        //         BASE_ETH_WRAPPED,
        //         BASE_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for BASE chain");
        // }

        if (chainId != ETH_CHAIN_ID) {
            setPeersForChain(
                wrappedBTC,
                stakedBTC,
                wrappedUSD,
                stakedUSD,
                wrappedETH,
                stakedETH,
                wrappedEURC,
                stakedEURC,
                ETH_CHAIN_ID,
                ETH_BTC_WRAPPED,
                ETH_BTC_STAKED,
                ETH_USD_WRAPPED,
                ETH_USD_STAKED,
                ETH_ETH_WRAPPED,
                ETH_ETH_STAKED,
                ETH_EURC_WRAPPED,
                ETH_EURC_STAKED
            );
            console2.log("\nSet peers for ETH chain");
        }

        // if (chainId != SONIC_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         SONIC_CHAIN_ID,
        //         SONIC_BTC_WRAPPED,
        //         SONIC_BTC_STAKED,
        //         SONIC_USD_WRAPPED,
        //         SONIC_USD_STAKED,
        //         SONIC_ETH_WRAPPED,
        //         SONIC_ETH_STAKED
        //     );
        //     console2.log("\nSet peers for SONIC chain");
        // }

        // if (chainId != HYPEREVM_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         HYPEREVM_CHAIN_ID,
        //         HYPEREVM_BTC_WRAPPED,
        //         HYPEREVM_BTC_STAKED,
        //         HYPEREVM_USD_WRAPPED,
        //         HYPEREVM_USD_STAKED,
        //         HYPEREVM_ETH_WRAPPED,
        //         HYPEREVM_ETH_STAKED,
        //         HYPEREVM_EURC_WRAPPED,
        //         HYPEREVM_EURC_STAKED
        //     );
        //     console2.log("\nSet peers for HYPEREVM chain");
        // }

        // if (chainId != LINEA_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         LINEA_CHAIN_ID,
        //         LINEA_BTC_WRAPPED,
        //         LINEA_BTC_STAKED,
        //         LINEA_USD_WRAPPED,
        //         LINEA_USD_STAKED,
        //         LINEA_ETH_WRAPPED,
        //         LINEA_ETH_STAKED,
        //         LINEA_EURC_WRAPPED,
        //         LINEA_EURC_STAKED
        //     );
        //     console2.log("\nSet peers for LINEA chain");
        // }

        // if (chainId != PLUME_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         PLUME_CHAIN_ID,
        //         PLUME_BTC_WRAPPED,
        //         PLUME_BTC_STAKED,
        //         PLUME_USD_WRAPPED,
        //         PLUME_USD_STAKED,
        //         PLUME_ETH_WRAPPED,
        //         PLUME_ETH_STAKED,
        //         PLUME_EURC_WRAPPED,
        //         PLUME_EURC_STAKED
        //     );
        //     console2.log("\nSet peers for PLUME chain");
        // }

        // if (chainId != KATANA_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         KATANA_CHAIN_ID,
        //         KATANA_BTC_WRAPPED,
        //         KATANA_BTC_STAKED,
        //         KATANA_USD_WRAPPED,
        //         KATANA_USD_STAKED,
        //         KATANA_ETH_WRAPPED,
        //         KATANA_ETH_STAKED,
        //         KATANA_EURC_WRAPPED,
        //         KATANA_EURC_STAKED
        //     );
        //     console2.log("\nSet peers for KATANA chain");
        // }

        // if (chainId != POLYGON_CHAIN_ID) {
        //     setPeersForChain(
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         POLYGON_CHAIN_ID,
        //         POLYGON_BTC_WRAPPED,
        //         POLYGON_BTC_STAKED,
        //         POLYGON_USD_WRAPPED,
        //         POLYGON_USD_STAKED,
        //         POLYGON_ETH_WRAPPED,
        //         POLYGON_ETH_STAKED,
        //         POLYGON_EURC_WRAPPED,
        //         POLYGON_EURC_STAKED
        //     );
        //     console2.log("\nSet peers for POLYGON chain");
        // }

        if (chainId != PLASMA_CHAIN_ID) {
            setPeersForChain(
                wrappedBTC,
                stakedBTC,
                wrappedUSD,
                stakedUSD,
                wrappedETH,
                stakedETH,
                wrappedEURC,
                stakedEURC,
                PLASMA_CHAIN_ID,
                PLASMA_BTC_WRAPPED,
                PLASMA_BTC_STAKED,
                PLASMA_USD_WRAPPED,
                PLASMA_USD_STAKED,
                PLASMA_ETH_WRAPPED,
                PLASMA_ETH_STAKED,
                PLASMA_EURC_WRAPPED,
                PLASMA_EURC_STAKED
            );
            console2.log("\nSet peers for PLASMA chain");
        }

        vm.stopBroadcast();

    }

    function setPeersForChain(
        address wrappedBTC,
        address stakedBTC,
        address wrappedUSD,
        address stakedUSD,
        address wrappedETH,
        address stakedETH,
        address wrappedEURC,
        address stakedEURC,
        uint32 chainId,
        address peerWrappedBTC,
        address peerStakedBTC,
        address peerWrappedUSD,
        address peerStakedUSD,
        address peerWrappedETH,
        address peerStakedETH,
        address peerWrappedEURC,
        address peerStakedEURC
    ) internal {
        MyOFT(wrappedBTC).setPeer(chainId, addressToBytes32(peerWrappedBTC));
        MyOFT(stakedBTC).setPeer(chainId, addressToBytes32(peerStakedBTC));
        MyOFT(wrappedUSD).setPeer(chainId, addressToBytes32(peerWrappedUSD));
        MyOFT(stakedUSD).setPeer(chainId, addressToBytes32(peerStakedUSD));
        MyOFT(wrappedETH).setPeer(chainId, addressToBytes32(peerWrappedETH));
        MyOFT(stakedETH).setPeer(chainId, addressToBytes32(peerStakedETH));
        MyOFT(wrappedEURC).setPeer(chainId, addressToBytes32(peerWrappedEURC));
        MyOFT(stakedEURC).setPeer(chainId, addressToBytes32(peerStakedEURC));
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
            address wrappedEURC,
            address stakedEURC,
            uint32 chainId
        )
    {
        bytes32 chainHash = keccak256(bytes(chain));

        if (chainHash == keccak256(bytes("ETH"))) {
            return (
                ETH_BTC_WRAPPED,
                ETH_BTC_STAKED,
                ETH_USD_WRAPPED,
                ETH_USD_STAKED,
                ETH_ETH_WRAPPED,
                ETH_ETH_STAKED,
                ETH_EURC_WRAPPED,
                ETH_EURC_STAKED,
                ETH_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("HYPEREVM"))) {
            return (
                HYPEREVM_BTC_WRAPPED,
                HYPEREVM_BTC_STAKED,
                HYPEREVM_USD_WRAPPED,
                HYPEREVM_USD_STAKED,
                HYPEREVM_ETH_WRAPPED,
                HYPEREVM_ETH_STAKED,
                HYPEREVM_EURC_WRAPPED,
                HYPEREVM_EURC_STAKED,
                HYPEREVM_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("LINEA"))) {
            return (
                LINEA_BTC_WRAPPED,
                LINEA_BTC_STAKED,
                LINEA_USD_WRAPPED,
                LINEA_USD_STAKED,
                LINEA_ETH_WRAPPED,
                LINEA_ETH_STAKED,
                LINEA_EURC_WRAPPED,
                LINEA_EURC_STAKED,
                LINEA_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("PLUME"))) {
            return (
                PLUME_BTC_WRAPPED,
                PLUME_BTC_STAKED,
                PLUME_USD_WRAPPED,
                PLUME_USD_STAKED,
                PLUME_ETH_WRAPPED,
                PLUME_ETH_STAKED,
                PLUME_EURC_WRAPPED,
                PLUME_EURC_STAKED,
                PLUME_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("KATANA"))) {
            return (
                KATANA_BTC_WRAPPED,
                KATANA_BTC_STAKED,
                KATANA_USD_WRAPPED,
                KATANA_USD_STAKED,
                KATANA_ETH_WRAPPED,
                KATANA_ETH_STAKED,
                KATANA_EURC_WRAPPED,
                KATANA_EURC_STAKED,
                KATANA_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("POLYGON"))) {
            return (
                POLYGON_BTC_WRAPPED,
                POLYGON_BTC_STAKED,
                POLYGON_USD_WRAPPED,
                POLYGON_USD_STAKED,
                POLYGON_ETH_WRAPPED,
                POLYGON_ETH_STAKED,
                POLYGON_EURC_WRAPPED,
                POLYGON_EURC_STAKED,
                POLYGON_CHAIN_ID
            );
        } else if (chainHash == keccak256(bytes("PLASMA"))) {
            return (
                PLASMA_BTC_WRAPPED,
                PLASMA_BTC_STAKED,
                PLASMA_USD_WRAPPED,
                PLASMA_USD_STAKED,
                PLASMA_ETH_WRAPPED,
                PLASMA_ETH_STAKED,
                PLASMA_EURC_WRAPPED,
                PLASMA_EURC_STAKED,
                PLASMA_CHAIN_ID
            );
        } else revert("Invalid chain");
    }
}
