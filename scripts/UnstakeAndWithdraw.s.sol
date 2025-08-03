// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";

contract UnstakeAndWithdrawScript is Script {
    // Address of the StreamVault contract
    address constant STREAM_VAULT = 0x7E586fBaF3084C0be7aB5C82C04FfD7592723153;
    // Address to prank
    address constant PRANKED_ADDRESS =
        0x1B200c7163826a363b5531016a4f0bc8b0277453;

    function run() public {
        // Get contract instance
        StreamVault vault = StreamVault(payable(STREAM_VAULT));

        // Start broadcasting as the pranked address
        vm.startPrank(PRANKED_ADDRESS);

        // You can adjust these values as needed
        uint256 numShares = 101827242718534020000; // Example amount of shares to unstake
        uint256 minAmountOut = 102062575287130629108; // Minimum amount of tokens to receive, set to 0 for no minimum

        // Call unstakeAndWithdraw
        vault.unstakeAndWithdraw(numShares, minAmountOut);

        vm.stopPrank();
    }
}
