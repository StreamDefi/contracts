// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMessageLibManager {
    function getSendLibrary(address _oapp, uint32 _eid) external view returns (address);
}

contract CheckSendLibraryScript is Script {
    function run() public view {
        // Arbitrum LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x1a44076050125825900e736c501f859c50fE728c);

        address currentLib = endpoint.getSendLibrary(
            0x212187708d01A63bcbE2F59553537de407a5621D,  // oApp address on Arbitrum
            30106                                          // Avalanche EID
        );

        console2.log("Current send library:", currentLib);
    }
}
