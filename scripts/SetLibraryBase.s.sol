// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";

// Define the interface locally
interface IMessageLibManager {
    function setSendLibrary(address _oapp, uint32 _dstEid, address _lib) external;
}

contract SetLibraryBaseScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Base LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x1a44076050125825900e736c501f859c50fE728c);

        vm.startBroadcast(deployerPrivateKey);

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0x6242EfAC2E1A85bB9ECFc10895da6e2928C89Fb1,  // StreamVault address on Base
            30101,                                         // ETH EID
            0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2    // send library
        );

        vm.stopBroadcast();
    }
}
