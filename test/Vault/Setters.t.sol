// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Base} from "./Base.t.sol";

/*
  TESTS
  =====
  - set keeper
  - set cap
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

contract StreamVaultSettersTest is Test, Base {
    /************************************************
     *  SET NEW KEEPER TESTS
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
    }

    function test_RevertIfOldKeeperMakesCallAfterChanged() public {
        vm.prank(owner);
        vault.setNewKeeper(keeper2);
        assertEq(vault.keeper(), keeper2);
        vm.startPrank(keeper);
        vm.expectRevert("!keeper");
        vault.rollToNextRound(0);
        vm.stopPrank();
    }

    /************************************************
     *  SET CAP TESTING
     ***********************************************/

    function test_RevertIfCapIsSetToZero() public {
        (, , , uint104 cap) = vault.vaultParams();
        vm.startPrank(owner);
        vm.expectRevert("!newCap");
        vault.setCap(0);
        vm.stopPrank();
        // ensure old cap remains
        assertEq(cap, vaultCap);
    }

    function test_RevertIfCapDoesntFitIn104Bits(uint256 newCap) public {
        (, , , uint104 cap) = vault.vaultParams();
        vm.assume(newCap > type(uint104).max);
        vm.startPrank(owner);
        vm.expectRevert();
        vault.setCap(newCap);
        // ensure old cap remains
        assertEq(cap, vaultCap);
    }

    function test_newCapGetsSet(uint104 newCap) public {
        vm.assume(newCap > 0);
        vm.prank(owner);
        vault.setCap(newCap);
        (, , , uint104 cap) = vault.vaultParams();
        assertEq(cap, newCap);
    }

    function test_NonOwnerCannotCallSetCap(
        address fakeOwner,
        uint104 newCap
    ) public {
        (, , , uint104 capBefore) = vault.vaultParams();
        vm.assume(newCap > 0);
        vm.assume(fakeOwner != owner);
        vm.startPrank(fakeOwner);
        vm.expectRevert();
        vault.setCap(newCap);
        vm.stopPrank();
        (, , , uint104 capAfter) = vault.vaultParams();
        assertEq(capBefore, capAfter);
    }

    function test_canSetCapBelowCurrentDeposits() public {
        vm.deal(depositer1, vaultCap);
        vm.prank(depositer1);
        vault.depositETH{value: vaultCap}();
        vm.prank(owner);
        vault.setCap(vaultCap - 1 ether);
        (, , , uint104 cap) = vault.vaultParams();
        assertEq(cap, vaultCap - 1 ether);

        // ensure that the cap worked
        vm.startPrank(depositer2);
        vm.expectRevert();
        vault.depositETH{value: 1 ether}();
        vm.stopPrank();
    }
}
