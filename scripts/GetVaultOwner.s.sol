// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";

contract GetVaultOwnerScript is Script {
    function run() public view {
        // The StreamVault contract address
        address vaultAddress = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
        StreamVault vault = StreamVault(payable(address(vaultAddress)));

        address owner = vault.owner();
        console2.log("Vault Owner:", owner);
    }
}
