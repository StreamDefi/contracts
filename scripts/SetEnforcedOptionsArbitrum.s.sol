// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {EnforcedOptionParam} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract SetEnforcedOptionsArbitrumScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Chain IDs
        uint32 BASE_EID = 30184;

        // Create array of enforced options
        EnforcedOptionParam[] memory params = new EnforcedOptionParam[](1);
        params[0].eid = BASE_EID;
        params[0].msgType = 1;
        params[0].options = hex"0003010011010000000000000000000000000000ea60";

        vm.startBroadcast(deployerPrivateKey);

        // Call directly with the same struct type
        StableWrapper(payable(0x05F47d7CbB0F3d7f988E442E8C1401685D2CAbE0)).setEnforcedOptions(params);
        StreamVault(payable(0x12fd502e2052CaFB41eccC5B596023d9978057d6)).setEnforcedOptions(params);

        vm.stopBroadcast();
    }
}
