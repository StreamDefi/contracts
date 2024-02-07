// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {StreamVault} from "../../src/StreamVault.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {Base} from "../Base.t.sol";
import {VaultKeeper} from "../../src/VaultKeeper.sol";
import "forge-std/console.sol";

contract VaultKeeperTest is Test {
    VaultKeeper contractKeeper;

    StreamVault vault;
    MockERC20 weth;
    address depositer1;
    address owner;
    uint104 vaultCap;
    uint56 minSupply;
    uint256 singleShare = 10 ** 18;

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

    function setUp() public {
        weth = new MockERC20("wrapped ether", "WETH");

        vaultCap = uint104(10000000 * (10 ** 18));
        minSupply = 0.001 ether;
        depositer1 = vm.addr(1);
        owner = vm.addr(12);
        // valt cap of 10M WETH
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: address(weth),
            minimumSupply: minSupply,
            cap: vaultCap
        });

        vm.startPrank(owner);
        contractKeeper = new VaultKeeper();
        vault = new StreamVault(
            address(weth),
            address(contractKeeper),
            "StreamVault",
            "SV",
            vaultParams
        );
        contractKeeper.addVault("WETH", address(vault));
        vault.setPublic(true);
        vm.stopPrank();

        vm.startPrank(depositer1);
        weth.mint(depositer1, 1000 * (10 ** 18));
        weth.approve(address(vault), 1000 * (10 ** 18));
        vm.deal(depositer1, 100 * (10 ** 18));
        vm.stopPrank();
    }

    function test_rollRound(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();
        assertEq(weth.balanceOf(address(vault)), uint256(depositAmount));
        assertVaultState(
            StateChecker(1, 0, 0, uint128(depositAmount), 0, 0, 0, 0, 0)
        );
        vm.startPrank(owner);
        // none should be locked up yet
        uint256[] memory lockedAmounts = new uint256[](1);
        lockedAmounts[0] = 0;
        string[] memory vaults = new string[](1);
        vaults[0] = "WETH";
        contractKeeper.rollRound(vaults, lockedAmounts);
        assertVaultState(
            StateChecker(
                2,
                uint104(depositAmount),
                0,
                0,
                0,
                0,
                0,
                uint256(depositAmount),
                singleShare
            )
        );

        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(weth.balanceOf(address(contractKeeper)), 0);
        assertEq(weth.balanceOf(owner), depositAmount);

        lockedAmounts[0] = depositAmount;
        weth.approve(address(contractKeeper), depositAmount);
        contractKeeper.rollRound(vaults, lockedAmounts);

        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(weth.balanceOf(address(contractKeeper)), 0);
        assertEq(weth.balanceOf(owner), depositAmount);

        assertVaultState(
            StateChecker(
                3,
                uint104(depositAmount),
                uint104(depositAmount),
                0,
                0,
                0,
                0,
                uint256(depositAmount),
                singleShare
            )
        );
    }

    function test_DepositsToVaultOnWithdraw(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.startPrank(owner);
        // none should be locked up yet
        uint256[] memory lockedAmounts = new uint256[](1);
        lockedAmounts[0] = 0;
        string[] memory vaults = new string[](1);
        vaults[0] = "WETH";
        contractKeeper.rollRound(vaults, lockedAmounts);

        vm.stopPrank();
        vm.prank(depositer1);
        vault.initiateWithdraw(depositAmount - 100);

        vm.startPrank(owner);
        lockedAmounts[0] = depositAmount;
        weth.approve(address(contractKeeper), depositAmount - 100);
        contractKeeper.rollRound(vaults, lockedAmounts);

        assertVaultState(
            StateChecker(
                3,
                uint104(100),
                uint104(depositAmount),
                0,
                uint128(depositAmount - 100),
                uint256(depositAmount - 100),
                0,
                uint256(depositAmount),
                singleShare
            )
        );

        assertEq(weth.balanceOf(address(vault)), depositAmount - 100);
        assertEq(weth.balanceOf(address(contractKeeper)), 0);
        assertEq(weth.balanceOf(owner), 100);
    }

    function test_RevertIfNotEnoughToCoverWithdraw(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.startPrank(owner);
        // none should be locked up yet
        uint256[] memory lockedAmounts = new uint256[](1);
        lockedAmounts[0] = 0;
        string[] memory vaults = new string[](1);
        vaults[0] = "WETH";
        contractKeeper.rollRound(vaults, lockedAmounts);

        vm.stopPrank();
        vm.prank(depositer1);
        vault.initiateWithdraw(depositAmount - 100);
        weth.mint(owner, 1 ether);
        vm.startPrank(owner);
        lockedAmounts[0] = depositAmount;
        weth.approve(address(contractKeeper), depositAmount - 101);
        vm.expectRevert();
        contractKeeper.rollRound(vaults, lockedAmounts);
    }

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
}
