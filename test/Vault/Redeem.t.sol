// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Base} from "../Base.t.sol";

/*
  TESTS
  =====
  - external redeem
  - internal redeem
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

contract StreamVaultRedeemTest is Test, Base {
    /************************************************
     *  EXTERNAL REDEEM TESTS
     ***********************************************/

    function test_RevertIfRedeemingZero(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();
        vm.expectRevert("!numShares");
        vault.redeem(0);
    }

    /************************************************
     *  INTERNAL REDEEM TESTS
     ***********************************************/

    function test_redeemerReceivesSharesMax(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertEq(vault.shares(depositer1), depositAmount);
        assertEq(vault.balanceOf(depositer1), 0);

        vm.prank(depositer1);
        vault.maxRedeem();

        assertEq(vault.shares(depositer1), depositAmount);
        assertEq(vault.balanceOf(depositer1), depositAmount);
    }

    function test_redeemerReceivesSharesPartial() public {
        uint256 depositAmount = 1 ether;

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertEq(vault.shares(depositer1), depositAmount);
        assertEq(vault.balanceOf(depositer1), 0);

        vm.prank(depositer1);
        vault.redeem(depositAmount / 2);

        assertEq(vault.shares(depositer1), depositAmount);
        assertEq(vault.balanceOf(depositer1), depositAmount / 2);
    }

    function test_RevertIfRedeemingMoreThanAvailableShares(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);

        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vm.expectRevert("Exceeds available");
        vault.redeem(uint256(depositAmount) + 1);
    }

    function test_updatesDepositReceiptWhenRedeeming(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);

        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );

        vm.prank(depositer1);
        vault.redeem(depositAmount - 1);

        assertDepositReceipt(DepositReceiptChecker(depositer1, 1, 0, 1));

        vm.prank(depositer1);
        vault.maxRedeem();

        assertDepositReceipt(DepositReceiptChecker(depositer1, 1, 0, 0));
    }

    function test_nothingHappensWhenNumSharesIsZero() public {
        assertDepositReceipt(DepositReceiptChecker(depositer1, 0, 0, 0));
        assertEq(vault.shares(depositer1), 0);
        assertEq(vault.balanceOf(depositer1), 0);

        vm.prank(depositer1);
        vault.maxRedeem();

        assertDepositReceipt(DepositReceiptChecker(depositer1, 0, 0, 0));

        assertEq(vault.shares(depositer1), 0);

        assertEq(vault.balanceOf(depositer1), 0);
    }

    function test_redeemDoesntUpdateSameRoundDeposits(
        uint56 depositAmount1,
        uint56 depositAmount2
    ) public {
        vm.assume(depositAmount1 > minSupply);
        vm.assume(depositAmount2 > minSupply);

        vm.deal(depositer1, depositAmount1);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount1}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount1);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount1, 0)
        );

        vm.startPrank(depositer1);
        vm.deal(depositer1, depositAmount2);
        vault.depositETH{value: depositAmount2}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 2, depositAmount2, depositAmount1)
        );
        vault.maxRedeem();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 2, depositAmount2, 0)
        );
    }
}
