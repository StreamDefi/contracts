// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract GetErrorSelectorScript is Script {
    function run() public view {
        bytes32 hash = keccak256("LZ_SameValue()");
        bytes4 selector = bytes4(hash);
        
        console2.log("Error selector for LZ_SameValue():");
        console2.logBytes4(selector);
    }
}
