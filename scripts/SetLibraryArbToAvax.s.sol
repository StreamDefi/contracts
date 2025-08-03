// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMessageLibManager {
    function setSendLibrary(address _oapp, uint32 _dstEid, address _lib) external;
}

contract SetLibraryArbToAvaxScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Arbitrum LayerZero Endpoint
        IMessageLibManager endpoint = IMessageLibManager(0x1a44076050125825900e736c501f859c50fE728c);

        vm.startPrank(0x7447b12786116C3E2B92f5aA5476Eeef7F35bF8B);

        // Set send library on the endpoint for sending from Arbitrum to Avalanche
        endpoint.setSendLibrary(
            0x212187708d01A63bcbE2F59553537de407a5621D,  // oApp address on Arbitrum
            30106,                                         // Avalanche EID
            0x975bcD720be66659e3EB3C0e4F1866a3020E493A    // Arbitrum send library
        );

        vm.stopPrank();
    }
}
