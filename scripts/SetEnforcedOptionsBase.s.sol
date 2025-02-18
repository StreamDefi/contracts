// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";


contract SetEnforcedOptionsBaseScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Chain IDs
        uint32 ETHEREUM_EID = 30101;

        // Create array of enforced options
        EnforcedOptionParam[] memory params = new EnforcedOptionParam[](1);
        params[0].eid = ETHEREUM_EID;
        params[0].msgType = 1;  // SEND
        params[0].options = hex"0003010011010000000000000000000000000000ea60";  // 60k gas

        vm.startBroadcast(deployerPrivateKey);

        // Call directly with the same struct type
        StableWrapper(0x212187708d01A63bcbE2F59553537de407a5621D).setEnforcedOptions(params);  // BASE_WRAPPER
        StreamVault(0xa791082be08B890792c558F1292Ac4a2Dad21920).setEnforcedOptions(params);    // BASE_VAULT

        vm.stopBroadcast();
    }
}