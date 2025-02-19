// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TimelockController} from "../src/TimelockController.sol";

contract TimelockControllerTest is Test {
    function setUp() public {}

    function test_PrintSelectors() public {
        TimelockController timelock = new TimelockController(address(this));
        
        bytes4 rollToNextRound = bytes4(keccak256("rollToNextRound(uint256,bool)"));
        bytes4 processWithdrawals = bytes4(keccak256("processWithdrawals()"));
        
        console2.log("ROLL_TO_NEXT_ROUND selector:    ", vm.toString(rollToNextRound));
        console2.log("PROCESS_WITHDRAWALS selector:   ", vm.toString(processWithdrawals));
        
        assert(rollToNextRound == timelock.ROLL_TO_NEXT_ROUND());
        assert(processWithdrawals == timelock.PROCESS_WITHDRAWALS());
    }
} 