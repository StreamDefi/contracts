// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Base} from "./Base.t.sol";

/*
  TESTS
  =====
  - withdraw instantly 
  - initiate withdraw
  - complete withdraw
  - single withdraw simulations
  - multi withdraw simulations
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

contract StreamVaultWithdrawTest is Test, Base {
    /************************************************
     *  WITHDRAW INSTANTLY TESTS
     ***********************************************/

    function test_RevertsIfAmountIsNotGreaterThanZero() public {
        uint256 depositAmount = 1 ether;
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.expectRevert("!amount");
        vault.withdrawInstantly(0);
    }

    function test_RevertsIfInstantWithdrawExceedsDepositAmount(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.expectRevert("Exceed amount");
        vault.withdrawInstantly(uint256(depositAmount) + 1);
    }

    function test_RevertsIfAttemptingInstantWithdrawInPrevRound(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vm.expectRevert("Invalid round");
        vault.withdrawInstantly(depositAmount);
    }

    function test_fullInstantWithdrawUpdatesDepositReceipt(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount);

        assertDepositReceipt(DepositReceiptChecker(depositer1, 1, 0, 0));
    }

    function test_partialInstantWIthdrawUpdatesDepositReceipt() public {
        uint104 depositAmount = 1 ether;

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount / 2);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount / 2, 0)
        );
    }

    function test_fullInstantWithdrawUpdatesTotalPending(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        (, , , uint128 totalPending, ) = vault.vaultState();
        assertEq(totalPending, depositAmount);

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount);

        (, , , totalPending, ) = vault.vaultState();
        assertEq(totalPending, 0);
    }

    function test_partialInstantWithdrawUpdatesTotalPending() public {
        uint104 depositAmount = 1 ether;

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        (, , , uint128 totalPending, ) = vault.vaultState();
        assertEq(totalPending, depositAmount);

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount / 2);
        (, , , totalPending, ) = vault.vaultState();
        assertEq(totalPending, depositAmount / 2);
    }

    function test_fullInstantWithdrawUpdatesBalancesProperly(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(address(depositer1).balance, 0);
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount);

        assertEq(address(depositer1).balance, depositAmount);
        assertEq(weth.balanceOf(address(vault)), 0);
    }

    function test_partialInstantWithdrawUpdatesBalancesProperly() public {
        uint104 depositAmount = 1 ether;

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertEq(address(depositer1).balance, 0);
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.prank(depositer1);
        vault.withdrawInstantly(depositAmount / 2);

        assertEq(address(depositer1).balance, depositAmount / 2);
        assertEq(weth.balanceOf(address(vault)), depositAmount / 2);
    }

    /************************************************
     *  INITIATE WITHDRAW TESTS
     ***********************************************/

    function test_RevertIfInitatingZeroShareWithdraw(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vm.expectRevert("!numShares");
        vault.initiateWithdraw(0);
    }

    function test_maxRedeemsIfDepositerHasUnredeemedShares(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertEq(vault.balanceOf(address(vault)), depositAmount);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        // vault max redeems and transfers back to value the amount withdrawn
        assertEq(vault.balanceOf(depositer1), depositAmount - withdrawAmount);
        assertEq(vault.balanceOf(address(vault)), withdrawAmount);
    }

    function test_RevertIfDepositerHasNoUnreedeemedShares(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();
        vm.expectRevert();
        vault.initiateWithdraw(depositAmount);
    }

    function test_withdrawReceiptCreatedForNewWithdraw(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertWithdrawalReceipt(WithdrawalReceiptChecker(depositer1, 0, 0));

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, withdrawAmount)
        );
    }

    function test_doubleWithdrawAddsToWithdrawalReceipt(
        uint56 depositAmount,
        uint56 withdrawAmount1,
        uint56 withdrawAmount2
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount1 < depositAmount);
        vm.assume(withdrawAmount2 > 0);
        vm.assume(withdrawAmount2 < depositAmount);
        vm.assume(
            uint256(withdrawAmount1) + uint256(withdrawAmount2) <=
                uint256(depositAmount)
        );
        vm.assume(withdrawAmount1 > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertWithdrawalReceipt(WithdrawalReceiptChecker(depositer1, 0, 0));

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount1);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, withdrawAmount1)
        );

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount2);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(
                depositer1,
                2,
                withdrawAmount1 + withdrawAmount2
            )
        );
    }

    function test_RevertIfUserHasInsufficientShares(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vm.expectRevert();
        vault.initiateWithdraw(depositAmount + 1);
    }

    function test_RevertIfDoubleInitiatingWithdrawInSepRounds() public {
        uint256 depositAmount = 1 ether;
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.initiateWithdraw(depositAmount / 2);

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        vm.startPrank(depositer1);
        vm.expectRevert("Existing withdraw");
        vault.initiateWithdraw(depositAmount / 2);
    }

    function test_currentQueuedWithdrawSharesIsMaintained(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertEq(vault.currentQueuedWithdrawShares(), 0);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        assertEq(vault.currentQueuedWithdrawShares(), withdrawAmount);
    }

    /************************************************
     *  COMPLETE WITHDRAW TESTS
     ***********************************************/

    function test_RevertIfNoWithdrawInitiated(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vm.expectRevert("Not initiated");
        vault.completeWithdraw();
    }

    function test_RevertIfCompletingWithdrawPreMaturely(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.startPrank(depositer1);
        vault.initiateWithdraw(withdrawAmount);
        vm.expectRevert("Round not closed");
        vault.completeWithdraw();
    }

    function test_updatesWithdrawReceiptAfterCompleting(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertWithdrawalReceipt(WithdrawalReceiptChecker(depositer1, 0, 0));

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, withdrawAmount)
        );

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        vm.prank(depositer1);
        vault.completeWithdraw();

        assertWithdrawalReceipt(WithdrawalReceiptChecker(depositer1, 2, 0));
    }

    function test_withdrawerReceivesFundsFromVault(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        assertEq(weth.balanceOf(keeper), depositAmount);
        assertEq(weth.balanceOf(address(vault)), 0);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        assertEq(weth.balanceOf(keeper), depositAmount);
        assertEq(weth.balanceOf(address(vault)), 0);

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        assertEq(weth.balanceOf(address(vault)), withdrawAmount);
        assertEq(weth.balanceOf(keeper), depositAmount - withdrawAmount);

        uint256 preBal = depositer1.balance;

        vm.prank(depositer1);
        vault.completeWithdraw();

        uint256 postBal = depositer1.balance;

        assertEq(weth.balanceOf(keeper), depositAmount - withdrawAmount);
        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(preBal + uint256(withdrawAmount), postBal);
    }

    function test_queuedWithdrawSharesIsProperlyMaintained(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        (, , , , uint128 queuedWithdrawShares) = vault.vaultState();

        assertEq(queuedWithdrawShares, withdrawAmount);

        vm.prank(depositer1);
        vault.completeWithdraw();
        (, , , , queuedWithdrawShares) = vault.vaultState();
        assertEq(queuedWithdrawShares, 0);
    }

    function test_sharesGetBurnedOnComplete(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        assertEq(vault.totalSupply(), depositAmount);

        vm.prank(depositer1);
        vault.completeWithdraw();

        assertEq(
            vault.totalSupply(),
            uint256(depositAmount) - uint256(withdrawAmount)
        );
    }

    function test_lastQueuedWithdrawAmountIsProperlyMaintained(
        uint56 depositAmount,
        uint56 withdrawAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.assume(withdrawAmount < depositAmount);
        vm.assume(withdrawAmount > 0);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.initiateWithdraw(withdrawAmount);

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount);
        vm.stopPrank();

        assertEq(vault.lastQueuedWithdrawAmount(), withdrawAmount);

        vm.prank(depositer1);
        vault.completeWithdraw();

        assertEq(vault.lastQueuedWithdrawAmount(), 0);
    }

    /************************************************
     *  SINGLE  WITHDRAW TESTS
     ***********************************************/

    function test_singleInstantWithdrawETH() public {
        uint104 depositAmount = 1 ether;

        vm.startPrank(depositer1);
        // deposit 1 WETH
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        // instant withdraw
        vault.withdrawInstantly(depositAmount);
        assertDepositReceipt(DepositReceiptChecker(depositer1, 1, 0, 0));
        assertVaultState(StateChecker(1, 0, 0, 0, 0, 0, 0, 0, 0));

        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(address(depositer1).balance, 100 * (10 ** 18));

        vm.stopPrank();
    }

    function test_singleInitiateWithdrawFull() public {
        uint104 depositAmount = 1 ether;

        vm.startPrank(depositer1);
        // deposit 1 WETH
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.stopPrank();

        vm.startPrank(keeper);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();
        vm.startPrank(depositer1);
        vault.initiateWithdraw(depositAmount);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, depositAmount)
        );
        assertEq(vault.balanceOf(address(vault)), depositAmount);
    }

    function test_singleInitaiteWithdrawPartly() public {
        uint104 depositAmount = 1 ether;

        vm.startPrank(depositer1);
        // deposit 1 WETH
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.stopPrank();

        vm.startPrank(keeper);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();
        vm.startPrank(depositer1);
        vault.initiateWithdraw(depositAmount / 2);

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, depositAmount / 2)
        );
        assertEq(vault.balanceOf(address(vault)), depositAmount / 2);
    }

    function test_singleCompleteWithdraw() public {
        uint104 depositAmount = 1 ether;

        vm.startPrank(depositer1);
        // deposit 1 WETH
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));
        assertEq(weth.balanceOf(address(vault)), depositAmount);

        vm.stopPrank();

        vm.startPrank(keeper);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();

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

        // initiate the withdraw
        vm.startPrank(depositer1);
        vault.initiateWithdraw(depositAmount);
        vm.stopPrank();

        // roll over to next round
        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();

        assertVaultState(
            StateChecker(
                3,
                0,
                depositAmount,
                0,
                depositAmount,
                depositAmount,
                0,
                depositAmount,
                depositAmount
            )
        );

        assertWithdrawalReceipt(
            WithdrawalReceiptChecker(depositer1, 2, depositAmount)
        );

        //complete the withdraw
        vm.startPrank(depositer1);
        vault.completeWithdraw();
        vm.stopPrank();

        assertVaultState(
            StateChecker(3, 0, depositAmount, 0, 0, 0, 0, 0, depositAmount)
        );

        assertEq(weth.balanceOf(address(vault)), 0);

        assertWithdrawalReceipt(WithdrawalReceiptChecker(depositer1, 2, 0));
    }

    /************************************************
     *  MULTI  WITHDRAW TESTS
     ***********************************************/
    function test_multiInitiateWithdraw() public {
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
            vm.startPrank(depositors[i]);
            vault.initiateWithdraw(depositAmount);
            vm.stopPrank();
            assertWithdrawalReceipt(
                WithdrawalReceiptChecker(depositors[i], 2, depositAmount)
            );
        }

        assertEq(
            vault.balanceOf(address(vault)),
            depositAmount * depositors.length
        );
    }

    function test_multiCompleteWithdraw() public {
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

        assertEq(
            weth.balanceOf(address(keeper)),
            depositors.length * depositAmount
        );

        for (uint i = 0; i < depositors.length; ++i) {
            vm.startPrank(depositors[i]);
            vault.initiateWithdraw(depositAmount);
            vm.stopPrank();
            assertWithdrawalReceipt(
                WithdrawalReceiptChecker(depositors[i], 2, depositAmount)
            );
        }

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount * depositors.length);
        vault.rollToNextRound(
            weth.balanceOf(address(vault)) + weth.balanceOf(address(keeper))
        );
        vm.stopPrank();

        assertVaultState(
            StateChecker(
                3,
                0,
                uint104(depositAmount * depositors.length),
                0,
                uint128(depositAmount * depositors.length),
                depositAmount * depositors.length,
                0,
                depositAmount * depositors.length,
                depositAmount
            )
        );

        for (uint i = 0; i < depositors.length; ++i) {
            assertWithdrawalReceipt(
                WithdrawalReceiptChecker(depositors[i], 2, depositAmount)
            );
        }

        //complete the withdraw
        for (uint i = 0; i < depositors.length; ++i) {
            vm.startPrank(depositors[i]);
            vault.completeWithdraw();
            vm.stopPrank();
            assertWithdrawalReceipt(
                WithdrawalReceiptChecker(depositors[i], 2, 0)
            );
        }

        assertVaultState(
            StateChecker(
                3,
                0,
                uint104(depositAmount * depositors.length),
                0,
                0,
                0,
                0,
                0,
                depositAmount
            )
        );

        assertEq(weth.balanceOf(address(vault)), 0);
    }
}
