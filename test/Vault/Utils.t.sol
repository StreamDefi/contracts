// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Base} from "./Base.t.sol";

/*
  TESTS
  =====
  - utils 
  - internal transfer asset
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

contract StreamVaultUtilsTest is Test, Base {
    /************************************************
     *  UTILS TEST
     ***********************************************/

    function test_decimals() public {
        assertEq(vault.decimals(), 18);
    }

    function test_cap() public {
        assertEq(vault.cap(), uint104(10000000 * (10 ** 18)));
    }

    function test_totalPending() public {
        assertEq(vault.totalPending(), 0);

        uint256 depositAmount = 1 ether;
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(vault.totalPending(), depositAmount);
    }

    function test_round() public {
        assertEq(vault.round(), 1);
        vm.deal(depositer1, 1 ether);
        vm.prank(depositer1);
        vault.depositETH{value: 1 ether}();
        vm.prank(keeper);
        vault.rollToNextRound(1 ether);
        assertEq(vault.round(), 2);
    }

    function test_receive() public {
        assertEq(address(vault).balance, 0);
        vm.deal(depositer1, 1 ether);
        vm.prank(depositer1);
        (payable(address(vault))).transfer(1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    /************************************************
     *  INTERNAL TRANSFER ASSET TESTS
     ***********************************************/
}
