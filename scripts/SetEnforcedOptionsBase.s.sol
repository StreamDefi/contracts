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
        uint32 BASE_EID = 30184;

        // Create array of enforced options
        EnforcedOptionParam[] memory params = new EnforcedOptionParam[](2);
        params[0].eid = ETHEREUM_EID;
        params[0].msgType = 1; // SEND
        params[0].options = hex"0003010011010000000000000000000000000000ea60"; // 60k gas
        params[1].eid = BASE_EID;
        params[1].msgType = 1; // SEND
        params[1].options = hex"0003010011010000000000000000000000000000ea60"; // 60k gas

        vm.startBroadcast(deployerPrivateKey);

        // Call directly with the same struct type
        StableWrapper(payable(0x34F3D5120931CfAb0b3149858B8c17D51d68E0D6))
            .setEnforcedOptions(params); // BASE_WRAPPER
        StreamVault(payable(0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926))
            .setEnforcedOptions(params); // BASE_VAULT

        vm.stopBroadcast();
    }
}
