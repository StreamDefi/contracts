// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

contract AddressToBytes32Script is Script {
    function run() public view {
        address addr = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
        bytes32 b32 = bytes32(uint256(uint160(addr)));
        console2.logBytes32(b32);
    }
}
