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

        // Base Sepolia LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x6EDCE65403992e310A62460808c4b910D972f10f);

        vm.startBroadcast(deployerPrivateKey);

        // Set send library on the endpoint
        endpoint.setSendLibrary(
            0x6242EfAC2E1A85bB9ECFc10895da6e2928C89Fb1,  // StreamVault address on Arbitrum
            40231,                                         // Base Sepolia EID
            0xC1868e054425D378095A003EcbA3823a5D0135C9    // send library
        );

        vm.stopBroadcast();
    }
}
