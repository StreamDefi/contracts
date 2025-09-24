// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract MultiTransferOwnershipScript is Script {
    // NEW OWNER ADDRESS - HARDCODED
    address constant NEW_OWNER = 0x1597E4B7cF6D2877A1d690b6088668afDb045763; // TODO: Replace with actual address

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
            address stakedEURC
        ) = getChainInfo(currentChain);

        console2.log("\nTransferring ownership for chain:", currentChain);
        console2.log("New owner address:", NEW_OWNER);

        vm.startBroadcast(deployerPrivateKey);

        // Transfer ownership for all contracts
        IOwnable(wrappedBTC).transferOwnership(NEW_OWNER);
        IOwnable(stakedBTC).transferOwnership(NEW_OWNER);
        IOwnable(wrappedUSD).transferOwnership(NEW_OWNER);
        IOwnable(stakedUSD).transferOwnership(NEW_OWNER);
        IOwnable(wrappedETH).transferOwnership(NEW_OWNER);
        IOwnable(stakedETH).transferOwnership(NEW_OWNER);
        IOwnable(wrappedEURC).transferOwnership(NEW_OWNER);
        IOwnable(stakedEURC).transferOwnership(NEW_OWNER);

        console2.log("\nOwnership transferred for contracts:");
        console2.log("BTC Wrapped:", wrappedBTC);
        console2.log("BTC Staked:", stakedBTC);
        console2.log("USD Wrapped:", wrappedUSD);
        console2.log("USD Staked:", stakedUSD);
        console2.log("ETH Wrapped:", wrappedETH);
        console2.log("ETH Staked:", stakedETH);
        console2.log("EURC Wrapped:", wrappedEURC);
        console2.log("EURC Staked:", stakedEURC);

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
            address wrappedEURC,
            address stakedEURC
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
                ETH_EURC_STAKED
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
                HYPEREVM_EURC_STAKED
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
                LINEA_EURC_STAKED
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
                PLUME_EURC_STAKED
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
                KATANA_EURC_STAKED
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
                POLYGON_EURC_STAKED
            );
        } else {
            revert("Invalid chain");
        }
    }
}