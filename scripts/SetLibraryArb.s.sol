// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";

// Define the interface locally
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

contract SetLibraryArbScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint32 etheid = 30101;
        uint32 baseEid = 30184;
        uint32 sonicEid = 30332;

        address ethendpoint = 0x1a44076050125825900e736c501f859c50fE728c;
        address baseendpoint = 0x1a44076050125825900e736c501f859c50fE728c;
        address sonicendpoint = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;

        address ethSendlibrary = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
        address baseSendlibrary = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
        address sonicSendlibrary = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;

        address ethReceiveLibrary = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;

        // ETH LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(ethendpoint);

        vm.startBroadcast(deployerPrivateKey);

        endpoint.getConfig(
            
        )

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0x7E586fBaF3084C0be7aB5C82C04FfD7592723153, // StreamVault address on ETH
            sonicEid, // Base EID
            ethSendlibrary // send library
        );

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0xF70f54cEFdCd3C8f011865685FF49FB80A386a34, // StreamWrapper address on ETH
            sonicEid, // Base EID
            ethSendlibrary // send library
        );

        // endpoint.setReceiveLibrary(
        //     0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94, // StreamVault address on ETH
        //     sonicEid, // Base EID
        //     ethReceiveLibrary, // send library
        //     0
        // );

        // // Set send library on the endpoint
        // endpoint.setReceiveLibrary(
        //     0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C, // StreamWrapper address on ETH
        //     sonicEid, // Base EID
        //     ethReceiveLibrary, // send library
        //     0
        // );

        vm.stopBroadcast();
    }
}
