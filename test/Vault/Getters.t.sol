// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Base} from "../Base.t.sol";

/*
  TESTS
  =====
  - shares
  - price per share
  - account vault balance
  - total balance
  - share balances
  - current queued withdraw amount
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

contract StreamVaultGettersTest is Test, Base {
    /************************************************
     *  SHARES GETTER TESTS
     ***********************************************/

    function test_returnsUnredeemedSharesSingle(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        // shouldn't have any shares until round rollover
        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        // should now have shares
        assertEq(vault.shares(depositer1), depositAmount);
    }

    function test_returnUnredeemedSharesMultiple(
        uint56[5] memory depositAmounts
    ) public {
        uint256 totalAmount;
        for (uint i = 0; i < 5; ++i) {
            vm.assume(depositAmounts[i] > minSupply);
            vm.deal(depositors[i], depositAmounts[i]);
            vm.prank(depositors[i]);
            vault.depositETH{value: depositAmounts[i]}();
            totalAmount += uint256(depositAmounts[i]);
        }

        for (uint i = 0; i < 5; ++i) {
            assertEq(vault.shares(depositors[i]), 0);
        }

        vm.prank(keeper);
        vault.rollToNextRound(totalAmount);

        uint256 pricePerShare = vault.roundPricePerShare(1);

        for (uint i = 0; i < 5; ++i) {
            assertEq(
                (uint256(depositAmounts[i]) * (10 ** 18)) / pricePerShare,
                vault.shares(depositors[i])
            );
        }
    }

    function test_returnsRedeemedSharesSingle(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        // shouldn't have any shares until round rollover
        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.maxRedeem();

        assertEq(vault.shares(depositer1), depositAmount);
    }

    function test_returnsRedeemedSharesMultiple(
        uint56[5] memory depositAmounts
    ) public {
        uint256 totalAmount;
        for (uint i = 0; i < 5; ++i) {
            vm.assume(depositAmounts[i] > minSupply);
            vm.deal(depositors[i], depositAmounts[i]);
            vm.prank(depositors[i]);
            vault.depositETH{value: depositAmounts[i]}();
            totalAmount += uint256(depositAmounts[i]);
        }

        for (uint i = 0; i < 5; ++i) {
            assertEq(vault.shares(depositors[i]), 0);
        }

        vm.prank(keeper);
        vault.rollToNextRound(totalAmount);

        for (uint i = 0; i < 5; ++i) {
            vm.prank(depositors[i]);
            vault.maxRedeem();
        }

        uint256 pricePerShare = vault.roundPricePerShare(1);

        for (uint i = 0; i < 5; ++i) {
            assertEq(
                (uint256(depositAmounts[i]) * (10 ** 18)) / pricePerShare,
                vault.shares(depositors[i])
            );
        }
    }

    function test_returnsUnredeemedAndRedeemedSharesSingle(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        // shouldn't have any shares until round rollover
        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.maxRedeem();

        assertEq(vault.shares(depositer1), depositAmount);

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(uint256(depositAmount) * 2);
        vm.stopPrank();

        assertEq(vault.shares(depositer1), uint256(depositAmount) * 2);
    }

    function test_returnsUnredeemedAndRedeemedSharesMultiple(
        uint56[5] memory depositAmounts
    ) public {
        uint256 totalAmount;
        for (uint i = 0; i < 5; ++i) {
            vm.assume(depositAmounts[i] > minSupply);
            vm.deal(depositors[i], depositAmounts[i]);
            vm.prank(depositors[i]);
            vault.depositETH{value: depositAmounts[i]}();
            totalAmount += uint256(depositAmounts[i]);
        }

        for (uint i = 0; i < 5; ++i) {
            assertEq(vault.shares(depositors[i]), 0);
        }

        vm.prank(keeper);
        vault.rollToNextRound(totalAmount);

        for (uint i = 0; i < 5; ++i) {
            vm.prank(depositors[i]);
            vault.maxRedeem();
        }

        uint256 pricePerShare = vault.roundPricePerShare(1);

        for (uint i = 0; i < 5; ++i) {
            assertEq(
                (uint256(depositAmounts[i]) * (10 ** 18)) / pricePerShare,
                vault.shares(depositors[i])
            );
        }

        for (uint i = 0; i < 5; ++i) {
            vm.deal(depositors[i], depositAmounts[i]);
            vm.prank(depositors[i]);
            vault.depositETH{value: depositAmounts[i]}();
        }

        vm.startPrank(keeper);
        weth.transfer(address(vault), totalAmount);
        vault.rollToNextRound(totalAmount * 2);
        vm.stopPrank();

        pricePerShare = vault.roundPricePerShare(2);

        for (uint i = 0; i < 5; ++i) {
            assertEq(
                (uint256(depositAmounts[i]) * 2 * (10 ** 18)) / pricePerShare,
                vault.shares(depositors[i])
            );
        }
    }

    function test_returnsSharesAfterDoubleDeposit(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        // shouldn't have any shares until round rollover
        assertEq(vault.shares(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer1);
        vault.maxRedeem();

        assertEq(vault.shares(depositer1), depositAmount);

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(uint256(depositAmount) * 2);
        vm.stopPrank();

        assertEq(vault.shares(depositer1), uint256(depositAmount) * 2);

        vm.deal(depositer1, 1 ether);
        vm.prank(depositer1);
        vault.depositETH{value: 1 ether}();

        assertEq(vault.shares(depositer1), uint256(depositAmount) * 2);
    }

    /************************************************
     * PRICE PER SHARE TESTS
     ***********************************************/

    function test_pricePerShareNoDeposits() public {
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
    }

    function test_pricePerShareStaysConsistentWithNoProfit() public {
        uint256 depositAmount = 1 ether;
        uint256 depositAmount2 = 0.4 ether;
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);
        vm.deal(depositer2, depositAmount2);
        vm.prank(depositer2);
        vault.depositETH{value: depositAmount2}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
        vm.startPrank(keeper);
        weth.transfer(address(vault), depositAmount);
        vault.rollToNextRound(depositAmount + depositAmount2);
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
    }

    function test_pricePerShareWithProfit() public {
        uint256 depositAmount = 1 ether;
        uint256 depositAmount2 = 0.4 ether;
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.deal(depositer2, depositAmount2);
        vm.prank(depositer2);
        vault.depositETH{value: depositAmount2}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());

        // assume vault operator returned 0.6 ETH profit from the initial 1 ether deposit
        // this means 0.4/1.6 shares are minted on top of the 1 share already making total 1.25 shares outstanding
        vm.startPrank(keeper);
        vm.deal(keeper, 1 ether + 0.6 ether);
        weth.deposit{value: 1 ether + 0.6 ether}();
        weth.transfer(address(vault), 1 ether + 0.6 ether);
        vault.rollToNextRound(depositAmount2 + depositAmount + 0.6 ether);

        assertEq(
            vault.pricePerShare(),
            (2 ether * (10 ** vault.decimals())) / (depositAmount + 0.25 ether)
        );
    }

    function test_pricePerShareWithLoss() public {
        uint256 depositAmount = 1 ether;
        uint256 depositAmount2 = 0.4 ether;
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.deal(depositer2, depositAmount2);
        vm.prank(depositer2);
        vault.depositETH{value: depositAmount2}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());

        // assume vault operator incurred 0.2 ETH loss and returns 0.8 ETH
        // this means 0.4/0.8 shares are minted on top of the 1 share for depositor 2
        // making the total outstanding shares 1.5
        vm.startPrank(keeper);
        vm.deal(keeper, 0.8 ether);
        weth.deposit{value: 0.8 ether}();
        weth.transfer(address(vault), 0.8 ether);
        vault.rollToNextRound(depositAmount2 + 0.8 ether);

        assertEq(
            vault.pricePerShare(),
            (1.2 ether * (10 ** vault.decimals())) / (depositAmount + 0.5 ether)
        );
    }

    function test_unorthodoxDepositRemainsAccountedFor() public {
        uint256 depositAmount = 1 ether;
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(vault.pricePerShare(), 10 ** vault.decimals());
        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        vm.prank(depositer2);
        weth.transfer(address(vault), 0.5 ether);

        // depositors benefit from a user depositing without it being accounted for
        assertEq(vault.pricePerShare(), 1.5 ether);
    }

    /************************************************
     * ACCOUNT VAULT BALANCE TESTS
     ***********************************************/

    function test_accountVaultBalance() public {
        assertEq(vault.accountVaultBalance(depositer1), 0);
        vm.deal(depositer1, 1 ether);
        vm.prank(depositer1);
        vault.depositETH{value: 1 ether}();
        // doesn't account for current round deposits
        assertEq(vault.accountVaultBalance(depositer1), 0);

        vm.prank(keeper);
        vault.rollToNextRound(1 ether);
        assertEq(vault.accountVaultBalance(depositer1), 1 ether);
    }

    /************************************************
     * TOTAL BALANCE TESTS
     ***********************************************/

    function test_totalBalance() public {
        vm.deal(depositer1, 3 ether);
        vm.prank(depositer1);
        vault.depositETH{value: 1 ether}();
        vm.prank(keeper);
        vault.rollToNextRound(1 ether);
        assertEq(vault.totalBalance(), 1 ether);
    }

    /************************************************
     * GET CURRENT QUEUED WITHDRAW AMOUNT TESTS
     ***********************************************/

    function test_getCurrQueuedWithdrawAmount() public {
        assertEq(vault.getCurrQueuedWithdrawAmount(0), 0);
        vm.deal(depositer1, 3 ether);
        vm.prank(depositer1);
        vault.depositETH{value: 1 ether}();

        vm.prank(keeper);
        vault.rollToNextRound(1 ether);

        vm.prank(depositer1);
        vault.initiateWithdraw(1 ether / 2);
        assertEq(vault.getCurrQueuedWithdrawAmount(1 ether), 1 ether / 2);
    }

    /************************************************
     *  SHARE BALANCE TESTS
     ***********************************************/

    function test_shareBalancesReturnsProperly(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        (uint256 heldByAccount, uint256 heldByVault) = vault.shareBalances(
            depositer1
        );
        assertEq(heldByAccount, 0, "heldByAccount should be 0");
        assertEq(heldByVault, 0, "heldByVault should be 0");

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        (heldByAccount, heldByVault) = vault.shareBalances(depositer1);
        assertEq(heldByAccount, 0, "heldByAccount should still be 0");
        assertEq(heldByVault, 0, "heldByVault should still be 0");

        vm.prank(keeper);
        vault.rollToNextRound(depositAmount);

        (heldByAccount, heldByVault) = vault.shareBalances(depositer1);
        assertEq(heldByAccount, 0, "heldByAccount should still be 0");
        assertEq(
            heldByVault,
            depositAmount,
            "heldByVault should hold depositAMount"
        );

        vm.prank(depositer1);
        vault.redeem(depositAmount - 100);

        (heldByAccount, heldByVault) = vault.shareBalances(depositer1);
        assertEq(
            heldByAccount,
            depositAmount - 100,
            "heldByAccount should hold depositAmount - 100"
        );
        assertEq(heldByVault, 100, "heldByVault should hold 100");

        vm.prank(depositer1);
        vault.maxRedeem();

        (heldByAccount, heldByVault) = vault.shareBalances(depositer1);
        assertEq(
            heldByAccount,
            depositAmount,
            "heldByAccount should hold depositAmount"
        );
        assertEq(heldByVault, 0, "heldByVault should hold 0");
    }
}
