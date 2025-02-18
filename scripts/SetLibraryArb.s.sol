// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";

// Define the interface locally
interface IMessageLibManager {
    function setSendLibrary(address _oapp, uint32 _dstEid, address _lib) external;
}

contract SetLibraryArbScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Arbitrum Sepolia LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x1a44076050125825900e736c501f859c50fE728c);

        vm.startBroadcast(deployerPrivateKey);

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0x55b97D28E3df8d1879b581267dF0c2cEeE8505C3,  // StreamVault address on Arbitrum
            40245,                                         // Base Sepolia EID
            0x4f7cd4DA19ABB31b0eC98b9066B9e857B1bf9C0E    // send library
        );

        vm.stopBroadcast();
    }
}
