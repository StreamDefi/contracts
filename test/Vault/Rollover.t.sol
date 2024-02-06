// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {Base} from "../Base.t.sol";

/*
  TESTS
  =====
  - roll to next round
  - single rollover simulation
  - multi rollover simulation
*/

/*
  VAULT STATE
  ===========
  Deposit Receipts [{round, amount, unredeemedShares}]
  Round Price Per Share 
  Withdrawals [{round, shares}]
  Vault Params {decimals, asset, minimumSupply, cap}
  Vault State
    - round
    - lockedAmount
    - lastLockedAmount
    - totalPending
    - queuedWithdrawShares
  Last Queued Withdraw Amount
  Current Queued Withdraw Shares
 */

contract StreamVaultRolloverTest is Test, Base {
    /************************************************
     * ROLL TO NEXT ROUND TESTS
     ***********************************************/

    function test_rollToNextRound() public {
        Vault.VaultState memory state;
        (
            state.round,
            state.lockedAmount,
            state.lastLockedAmount,
            state.totalPending,
            state.queuedWithdrawShares
        ) = vault.vaultState();

        assertEq(state.round, uint16(1));

        vm.prank(depositer1);
        vm.deal(depositer1, 3 ether);
        vault.depositETH{value: 1 ether}();
        vm.prank(keeper);
        vault.rollToNextRound(1 ether);

        (
            state.round,
            state.lockedAmount,
            state.lastLockedAmount,
            state.totalPending,
            state.queuedWithdrawShares
        ) = vault.vaultState();
        assertEq(state.round, 2);
        assertEq(vault.balanceOf(address(vault)), 1 ether);
        assertEq(vault.roundPricePerShare(1), 1 ether);
        assertEq(state.totalPending, 0);
        assertEq(state.queuedWithdrawShares, 0);
        assertEq(state.lastLockedAmount, 0);
        assertEq(state.lockedAmount, 1 ether);
        assertEq(weth.balanceOf(keeper), 1 ether);
    }

    /************************************************
     *  SINGLE  ROLLOVER TESTS
     ***********************************************/

    function test_singleDepositWETHRollover() public {
        // deposit
        uint104 depositAmount = 1 ether;
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));
        assertEq(weth.balanceOf(address(vault)), depositAmount);
        vm.stopPrank();

        // rollover
        vm.startPrank(keeper);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();
        // totalLocked amount should be 1 eth and price per share should be 1
        // totalShare amount should be 1 eth
        assertVaultState(
            StateChecker(
                2,
                depositAmount,
                0,
                0,
                0,
                0,
                0,
                depositAmount,
                depositAmount
            )
        );

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(weth.balanceOf(address(keeper)), depositAmount);
    }

    /************************************************
     *  MULTI  ROLLOVER TESTS
     ***********************************************/

    function test_multiDepositETHRollover() public {
        // deposit
        uint104 depositAmount = 1 ether;
        for (uint256 i = 0; i < depositors.length; i++) {
            vm.startPrank(depositors[i]);
            vault.depositETH{value: depositAmount}();
            assertDepositReceipt(
                DepositReceiptChecker(depositors[i], 1, depositAmount, 0)
            );

            assertEq(weth.balanceOf(address(vault)), depositAmount * (i + 1));
            vm.stopPrank();
        }

        assertVaultState(
            StateChecker(
                1,
                0,
                0,
                uint128(depositAmount * depositors.length),
                0,
                0,
                0,
                0,
                0
            )
        );

        // rollover
        vm.startPrank(keeper);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();

        // totalLocked amount should be 1 eth and price per share should be 1
        // totalShare amount should be 1 eth
        assertVaultState(
            StateChecker(
                2,
                uint104(depositAmount * depositors.length),
                0,
                0,
                0,
                0,
                0,
                depositAmount * depositors.length,
                depositAmount
            )
        );

        for (uint i = 0; i < depositors.length; ++i) {
            assertDepositReceipt(
                DepositReceiptChecker(depositors[i], 1, depositAmount, 0)
            );
        }

        assertEq(weth.balanceOf(address(vault)), 0);

        assertEq(
            weth.balanceOf(address(keeper)),
            depositAmount * depositors.length
        );
    }
}
