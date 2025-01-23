// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Vault} from "../src/lib/Vault.sol";

contract Base is Test {
    StreamVault vault;
    MockERC20 weth;
    MockERC20 dummyAsset;

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
    address lzEndpoint;
    address lzDelegate;
    address owner;
    uint104 vaultCap;
    uint56 minSupply;
    uint256 _decimals = 18;
    uint256 singleShare = 10 ** _decimals;

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
        lzEndpoint = vm.addr(14);
        lzDelegate = vm.addr(15);

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
        dummyAsset = new MockERC20("dummy asset", "DUMMY");
        vaultCap = uint104(1000000000000000000000000);
        minSupply = (100000000);

        // valt cap of 10M WETH
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: uint8(_decimals),
            asset: address(weth),
            minimumSupply: minSupply,
            cap: vaultCap
        });

        vm.startPrank(owner);
        vault = new StreamVault(
            address(weth),
            keeper,
            lzEndpoint,
            lzDelegate,
            "StreamVault",
            "SV",
            vaultParams
        );
        vault.setPublic(true);
        vm.stopPrank();

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
