// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract SetEnforcedOptionsSonicScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Chain IDs
        uint32 ETHEREUM_EID = 30101;
        uint32 BASE_EID = 30184;
        uint32 SONIC_EID = 30332;

        // Create array of enforced options
        EnforcedOptionParam[] memory params = new EnforcedOptionParam[](1);
        params[0].eid = SONIC_EID;
        params[0].msgType = 1; // SEND
        params[0].options = hex"0003010011010000000000000000000000000000ea60"; // 60k gas

        vm.startBroadcast(deployerPrivateKey);

        // Call directly with the same struct type
        StableWrapper(payable(0x8A31D2D10f34aAF24A2c48713e213266bc01c68b))
            .setEnforcedOptions(params); // SONIC_WRAPPER
        StreamVault(payable(0x09Aed31D66903C8295129aebCBc45a32E9244a1f))
            .setEnforcedOptions(params); // SONIC_VAULT

        vm.stopBroadcast();
    }
}
