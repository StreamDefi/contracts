// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";

contract BatchDepositAndStakeScript is Script {
    // Update these arrays with the addresses and amounts you want to process
    address[] public recipients = [
        0x1234567890123456789012345678901234567890,
        0x2345678901234567890123456789012345678901,
        0x3456789012345678901234567890123456789012
        // Add more addresses as needed
    ];

    uint256[] public amounts = [
        1 ether,
        2 ether,
        3 ether
        // Add more amounts as needed - must match number of addresses
    ];

    function run() external {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get StreamVault address from environment variable
        address vaultAddress = vm.envAddress("STREAM_VAULT_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        StreamVault vault = StreamVault(vaultAddress);

        require(
            recipients.length == amounts.length,
            "Arrays must be same length"
        );

        // Loop through arrays and call depositAndStake for each address/amount pair
        for (uint256 i = 0; i < recipients.length; i++) {
            // Cast amount to uint104 since that's what the function expects
            vault.depositAndStake(uint104(amounts[i]), recipients[i]);
        }

        vm.stopBroadcast();
    }
}
