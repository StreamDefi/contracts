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

        // ETH LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x1a44076050125825900e736c501f859c50fE728c);

        vm.startBroadcast(deployerPrivateKey);

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0x6FbB289DD177D3F23673B04ba29fe611ad6707dc,  // StreamVault address on ETH
            30184,                                         // Base EID
            0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1    // send library
        );

        vm.stopBroadcast();
    }
}
