// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {StableWrapper} from "../../src/stableWrapper.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";

contract Base is Test {
    // contract
    StableWrapper stableWrapper;

    // assets
    MockERC20 usdc;

    // depositors
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

    // admin
    address keeper;
    address keeper2;
    address owner;

    // layerzero
    address lzEndpoint;
    address lzDelegate;

    // helper
    uint256 decimals = 18;

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

        keeper = vm.addr(11);
        keeper2 = vm.addr(12);
        owner = vm.addr(13);

        lzEndpoint = vm.addr(14);
        lzDelegate = vm.addr(15);

        usdc = new MockERC20("USD Coin", "USDC");

        vm.startPrank(owner);
        stableWrapper = new StableWrapper(
            address(usdc),
            "Wrapped USD Coin",
            "wUSDC",
            keeper,
            lzEndpoint,
            lzDelegate
        );
        vm.stopPrank();

        // fund deposirs with 10_000 USDC and 100 ETH each and approve vault
        for (uint256 i = 0; i < depositors.length; i++) {
            vm.startPrank(depositors[i]);
            usdc.mint(depositors[i], 10000 * (10 ** 6));
            usdc.approve(address(stableWrapper), 1000 * (10 ** 18));
            vm.deal(depositors[i], 10 * (10 ** 18));
            vm.stopPrank();
        }
    }

    function assertEpoch(uint32 expectedEpoch) public {
        uint32 currentEpoch = stableWrapper.currentEpoch();
        assertEq(currentEpoch, expectedEpoch, "current epoch");
    }

    function assertWithdrawalReceipt(address user, uint224 amount) public {
        (uint224 receiptAmount, uint32 receiptEpoch) = stableWrapper
            .withdrawalReceipts(user);
        assertEq(receiptAmount, amount, "withdrawal receipt amount");
        assertEq(
            receiptEpoch,
            stableWrapper.currentEpoch(),
            "withdrawal receipt epoch"
        );
    }

    function assertWrapperBalance(uint256 expectedBalance) public {
        _assertBalance(address(stableWrapper), expectedBalance);
    }

    function assertUserBalance(address user, uint256 expectedBalance) public {
        _assertBalance(user, expectedBalance);
    }

    function _assertBalance(address account, uint256 expectedBalance) public {
        assertEq(usdc.balanceOf(account), expectedBalance, "balance");
    }
}
