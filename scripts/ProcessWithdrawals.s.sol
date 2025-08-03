// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IStableWrapper {
    function processWithdrawals() external;
}

interface IStreamVault {
    function rollToNextRound(uint256 yield, bool isYieldPositive) external;
}

contract ProcessWithdrawalsScript is Script {
    // ETH USD Wrapped contract address
    address constant ETH_USD_WRAPPED =
        0xF70f54cEFdCd3C8f011865685FF49FB80A386a34;
    // ETH USD Staked (StreamVault) contract address
    address constant ETH_USD_STAKED =
        0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;

    function run() public {
        // Get contract instances
        IStableWrapper wrapper = IStableWrapper(ETH_USD_WRAPPED);
        IStreamVault vault = IStreamVault(ETH_USD_STAKED);

        vm.startPrank(0x1597E4B7cF6D2877A1d690b6088668afDb045763);

        // Process withdrawals
        wrapper.processWithdrawals();

        // Roll to next round
        vault.rollToNextRound(0, true);
        vm.stopPrank();
    }
}
