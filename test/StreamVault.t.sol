// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "forge-std/Test.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Vault} from "../src/lib/Vault.sol";
import "forge-std/console.sol";

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

contract StreamVaultTest is Test {
    StreamVault vault;
    MockERC20 weth;

    address depositer1;
    address depositer2;
    address depositer3;
    address depositer4;
    address depositer5;
    address depositer6;
    address depositer7;
    address depositer8;
    address depositer9;
    address depositer10;

    address[] depositors;

    address keeper;
    address keeper2;
    address owner;

    struct StateChecker {
        uint16 round;
        uint104 lockedAmount;
        uint104 lastLockedAmount;
        uint128 totalPending;
        uint128 queuedWithdrawShares;
        uint256 lastQueuedWithdrawAmount;
        uint256 currentQueuedWithdrawShares;
        uint256 totalShareSupply;
        uint256 currentRoundPricePerShare;
    }

    struct DepositReceiptChecker {
        address depositer;
        uint16 round;
        uint104 amount;
        uint128 unredeemedShares;
    }

    struct WithdrawalReceiptChecker {
        address withdrawer;
        uint16 round;
        uint256 shares;
    }

    function setUp() public {
        depositer1 = vm.addr(1);
        depositer2 = vm.addr(2);
        depositer3 = vm.addr(3);
        depositer4 = vm.addr(4);
        depositer5 = vm.addr(5);
        depositer6 = vm.addr(6);
        depositer7 = vm.addr(7);
        depositer8 = vm.addr(8);
        depositer9 = vm.addr(9);
        depositer10 = vm.addr(10);
        keeper = vm.addr(11);
        owner = vm.addr(12);
        keeper2 = vm.addr(13);

        depositors = [
            depositer1,
            depositer2,
            depositer3,
            depositer4,
            depositer5,
            depositer6,
            depositer7,
            depositer8,
            depositer9,
            depositer10
        ];
        weth = new MockERC20("wrapped ether", "WETH");

        // valt cap of 10M WETH
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: address(weth),
            minimumSupply: uint56(1),
            cap: uint104(10000000 * (10 ** 18))
        });

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            keeper,
            "StreamVault",
            "SV",
            vaultParams
        );

        // fund deposirs with 1000 WETH and 100 ETH each and approve vault
        for (uint256 i = 0; i < depositors.length; i++) {
            vm.startPrank(depositors[i]);
            weth.mint(depositors[i], 1000 * (10 ** 18));
            weth.approve(address(vault), 1000 * (10 ** 18));
            vm.deal(depositors[i], 100 * (10 ** 18));
            vm.stopPrank();
        }
    }

    /************************************************
     *  SINGLE DEPOSIT TESTS
     ***********************************************/
    function test_singleDepositETH() public {
        uint104 depositAmount = 1 ether;

        vm.startPrank(depositer1);
        // deposit 1 ETH
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
        assertVaultState(StateChecker(1, 0, 0, depositAmount, 0, 0, 0, 0, 0));

        assertEq(weth.balanceOf(address(vault)), depositAmount);
        vm.stopPrank();
    }

    /************************************************
     *  MULTI DEPOSIT TESTS
     ***********************************************/
    function test_multiDepositETH() public {
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

    /************************************************
     *  SET KEEPER TESTS
     ***********************************************/

    function test_RevertWhenSettingKeeperToZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("!newKeeper");
        vault.setNewKeeper(address(0));
        vm.stopPrank();
        // ensure vault keepers stays the same after attempting to set to zero adr
        assertEq(vault.keeper(), keeper);
    }

    function test_RevertWhenNonOwnerChangesKeeper(address fakeOwner) public {
        vm.assume(fakeOwner != owner);
        vm.startPrank(fakeOwner);
        vm.expectRevert();
        vault.setNewKeeper(keeper2);
        vm.stopPrank();
        // ensure vault keepers stays the same after attempting to set to zero adr
        assertEq(vault.keeper(), keeper);
    }

    function test_settingNewKeeper() public {
        vm.prank(owner);
        vault.setNewKeeper(keeper2);
        assertEq(vault.keeper(), keeper2);
        vm.prank(keeper2);
        vault.rollToNextRound(0);
    }

    function test_RevertIfOldKeeperMakesCallAfterChanged() public {
        vm.prank(owner);
        vault.setNewKeeper(keeper2);
        assertEq(vault.keeper(), keeper2);
        vm.prank(keeper2);
        vault.rollToNextRound(0);
        vm.startPrank(keeper);
        vm.expectRevert("!keeper");
        vault.rollToNextRound(0);
        vm.stopPrank();
    }

    /************************************************
     *  HELPER STATE ASSERTIONS
     ***********************************************/

    function assertVaultState(StateChecker memory state) public {
        (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares
        ) = vault.vaultState();
        uint256 lastQueuedWithdrawAmount = vault.lastQueuedWithdrawAmount();
        uint256 currentQueuedWithdrawShares = vault
            .currentQueuedWithdrawShares();
        uint256 currentRoundPricePerShare;
        if (state.round == 1) {
            currentRoundPricePerShare = vault.roundPricePerShare(round);
        } else {
            currentRoundPricePerShare = vault.roundPricePerShare(round - 1);
        }

        assertEq(round, state.round);

        assertEq(lockedAmount, state.lockedAmount);

        assertEq(lastLockedAmount, state.lastLockedAmount);

        assertEq(totalPending, state.totalPending);

        assertEq(queuedWithdrawShares, state.queuedWithdrawShares);

        assertEq(lastQueuedWithdrawAmount, state.lastQueuedWithdrawAmount);

        assertEq(
            currentQueuedWithdrawShares,
            state.currentQueuedWithdrawShares
        );

        assertEq(currentRoundPricePerShare, state.currentRoundPricePerShare);

        assertEq(vault.totalSupply(), state.totalShareSupply);
    }

    function assertDepositReceipt(DepositReceiptChecker memory receipt) public {
        (uint16 round, uint104 amount, uint128 unredeemedShares) = vault
            .depositReceipts(receipt.depositer);

        assertEq(round, receipt.round);
        assertEq(amount, receipt.amount);
        assertEq(unredeemedShares, receipt.unredeemedShares);
    }

    function assertWithdrawalReceipt(
        WithdrawalReceiptChecker memory receipt
    ) public {
        (uint16 round, uint128 shares) = vault.withdrawals(receipt.withdrawer);

        assertEq(round, receipt.round);
        assertEq(shares, receipt.shares);
    }
}
