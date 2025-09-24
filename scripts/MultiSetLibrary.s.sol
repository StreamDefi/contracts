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

    function setReceiveLibrary(
        address _oapp,
        uint32 _dstEid,
        address _lib,
        uint256 _gracePeriod
    ) external;
}

contract MultiSetLibraryScript is Script {
    // LZ Endpoints
    address constant ETH_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant HYPEREVM_ENDPOINT = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address constant LINEA_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant PLUME_ENDPOINT = 0xC1b15d3B262bEeC0e3565C11C9e0F6134BdaCB36;
    address constant KATANA_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant POLYGON_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant PLASMA_ENDPOINT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;


    address constant ETH_SEND_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant ETH_RECV_LIB = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address constant HYPEREVM_SEND_LIB = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address constant HYPEREVM_RECV_LIB = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address constant LINEA_SEND_LIB = 0x32042142DD551b4EbE17B6FEd53131dd4b4eEa06;
    address constant LINEA_RECV_LIB = 0xE22ED54177CE1148C557de74E4873619e6c6b205;
    address constant PLUME_SEND_LIB = 0xFe7C30860D01e28371D40434806F4A8fcDD3A098;
    address constant PLUME_RECV_LIB = 0x5B19bd330A84c049b62D5B0FC2bA120217a18C1C;
    address constant KATANA_SEND_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant KATANA_RECV_LIB = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address constant POLYGON_SEND_LIB = 0x6c26c61a97006888ea9E4FA36584c7df57Cd9dA3;
    address constant POLYGON_RECV_LIB = 0x1322871e4ab09Bc7f5717189434f97bBD9546e95;
    address constant PLASMA_SEND_LIB = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant PLASMA_RECV_LIB = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;



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
            address endpoint,
            uint32 chainId
        ) = getChainInfo(currentChain);

        console2.log("\nSetting library for chain:", currentChain);
        console2.log("Chain ID:", chainId);

        vm.startBroadcast(deployerPrivateKey);

        IMessageLibManager lzEndpoint = IMessageLibManager(endpoint);

        // Get current chain's library
        address currentSendLibrary;
        address currentRecvLibrary;
        if (keccak256(bytes(currentChain)) == keccak256(bytes("ETH"))) {
            currentSendLibrary = ETH_SEND_LIB;
            currentRecvLibrary = ETH_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("HYPEREVM"))) {
            currentSendLibrary = HYPEREVM_SEND_LIB;
            currentRecvLibrary = HYPEREVM_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("LINEA"))) {
            currentSendLibrary = LINEA_SEND_LIB;
            currentRecvLibrary = LINEA_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("PLUME"))) {
            currentSendLibrary = PLUME_SEND_LIB;
            currentRecvLibrary = PLUME_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("KATANA"))) {
            currentSendLibrary = KATANA_SEND_LIB;
            currentRecvLibrary = KATANA_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("POLYGON"))) {
            currentSendLibrary = POLYGON_SEND_LIB;
            currentRecvLibrary = POLYGON_RECV_LIB;
        } else if (keccak256(bytes(currentChain)) == keccak256(bytes("PLASMA"))) {
            currentSendLibrary = PLASMA_SEND_LIB;
            currentRecvLibrary = PLASMA_RECV_LIB;
        } else revert("Invalid chain");
    

        if (chainId != ETH_CHAIN_ID) {
            setLibraryForChain(
                lzEndpoint,
                wrappedBTC,
                stakedBTC,
                wrappedUSD,
                stakedUSD,
                wrappedETH,
                stakedETH,
                wrappedEURC,
                stakedEURC,
                ETH_CHAIN_ID,
                currentSendLibrary,
                currentRecvLibrary
            );
        }

        // if (chainId != HYPEREVM_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         HYPEREVM_CHAIN_ID,
        //         currentSendLibrary,
        //         currentRecvLibrary
        //     );
        // }

        // if (chainId != LINEA_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         LINEA_CHAIN_ID,
        //         currentSendLibrary,
        //         currentRecvLibrary
        //     );
        // }

        // if (chainId != PLUME_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         PLUME_CHAIN_ID,
        //         currentSendLibrary,
        //         currentRecvLibrary
        //     );
        // }

        // if (chainId != KATANA_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         KATANA_CHAIN_ID,
        //         currentSendLibrary,
        //         currentRecvLibrary
        //     );
        // }

        // if (chainId != POLYGON_CHAIN_ID) {
        //     setLibraryForChain(
        //         lzEndpoint,
        //         wrappedBTC,
        //         stakedBTC,
        //         wrappedUSD,
        //         stakedUSD,
        //         wrappedETH,
        //         stakedETH,
        //         wrappedEURC,
        //         stakedEURC,
        //         POLYGON_CHAIN_ID,
        //         currentSendLibrary,
        //         currentRecvLibrary
        //     );
        // }

        if (chainId != PLASMA_CHAIN_ID) {
            setLibraryForChain(
                lzEndpoint,
                wrappedBTC,
                stakedBTC,
                wrappedUSD,
                stakedUSD,
                wrappedETH,
                stakedETH,
                wrappedEURC,
                stakedEURC,
                PLASMA_CHAIN_ID,
                currentSendLibrary,
                currentRecvLibrary
            );
        }

        vm.stopBroadcast();

    }

    function setLibraryForChain(
        IMessageLibManager endpoint,
        address wrappedBTC,
        address stakedBTC,
        address wrappedUSD,
        address stakedUSD,
        address wrappedETH,
        address stakedETH,
        address wrappedEURC,
        address stakedEURC,
        uint32 chainId,
        address sendLib,
        address recvLib
    ) internal {
        endpoint.setSendLibrary(wrappedBTC, chainId, sendLib);
        endpoint.setSendLibrary(stakedBTC, chainId, sendLib);
        endpoint.setSendLibrary(wrappedUSD, chainId, sendLib);
        endpoint.setSendLibrary(stakedUSD, chainId, sendLib);
        endpoint.setSendLibrary(wrappedETH, chainId, sendLib);
        endpoint.setSendLibrary(stakedETH, chainId, sendLib);
        endpoint.setSendLibrary(wrappedEURC, chainId, sendLib);
        endpoint.setSendLibrary(stakedEURC, chainId, sendLib);
        endpoint.setReceiveLibrary(wrappedBTC, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(stakedBTC, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(wrappedUSD, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(stakedUSD, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(wrappedETH, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(stakedETH, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(wrappedEURC, chainId, recvLib, 0);
        endpoint.setReceiveLibrary(stakedEURC, chainId, recvLib, 0);
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
            address endpoint,
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
                ETH_ENDPOINT,
                ETH_CHAIN_ID
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
                LINEA_ENDPOINT,
                LINEA_CHAIN_ID
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
                HYPEREVM_ENDPOINT,
                HYPEREVM_CHAIN_ID
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
                PLUME_ENDPOINT,
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
                KATANA_ENDPOINT,
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
                POLYGON_ENDPOINT,
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
                PLASMA_ENDPOINT,
                PLASMA_CHAIN_ID
            );
        } else revert("Invalid chain");
    }
}
