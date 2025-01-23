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
    StreamVault vault2;

    MockERC20 weth;
    MockERC20 mock;

    address depositer1;

    address owner;

    address lzEndpoint;
    address lzDelegate;

    address manager1;
    address manager2;

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
        mock = new MockERC20("mock", "MOCK");

        vaultCap = uint104(10000000 * (10 ** 18));
        minSupply = 0.001 ether;
        owner = vm.addr(1);
        depositer1 = vm.addr(2);
        manager1 = vm.addr(3);
        manager2 = vm.addr(4);
        lzEndpoint = vm.addr(69);
        lzDelegate = vm.addr(70);
        // valt cap of 10M WETH
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: address(weth),
            minimumSupply: minSupply,
            cap: vaultCap
        });

        Vault.VaultParams memory vaultParamsMock = Vault.VaultParams({
            decimals: 18,
            asset: address(mock),
            minimumSupply: minSupply,
            cap: vaultCap
        });

        address[] memory vaults = new address[](0);
        // vaults[0] = address(vault);
        // vaults[1] = address(vault2);

        string[] memory tickers = new string[](0);
        // tickers[0] = "WETH";
        // tickers[1] = "MOCK";

        address[] memory managers = new address[](0);
        // managers[0] = manager1;
        // managers[1] = manager2;

        vm.startPrank(owner);
        contractKeeper = new VaultKeeper(tickers, managers, vaults);

        vault = new StreamVault(
            address(weth),
            address(contractKeeper),
            lzEndpoint,
            lzDelegate,
            "StreamVault",
            "SV",
            vaultParams
        );

        vault2 = new StreamVault(
            address(weth),
            address(contractKeeper),
            lzEndpoint,
            lzDelegate,
            "StreamVault",
            "SV",
            vaultParamsMock
        );

        contractKeeper.addVault("WETH", address(vault), manager1);
        contractKeeper.addVault("MOCK", address(vault2), manager2);
        vault.setPublic(true);
        vault2.setPublic(true);
        vm.stopPrank();

        vm.startPrank(depositer1);
        weth.mint(depositer1, 1000 * (10 ** 18));
        mock.mint(depositer1, 1000 * (10 ** 18));
        weth.approve(address(vault), 1000 * (10 ** 18));
        mock.approve(address(vault2), 1000 * (10 ** 18));
        vm.deal(depositer1, 100 * (10 ** 18));
        vm.stopPrank();
    }

    function test_rollRound(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vault.depositETH{value: depositAmount}();
        mock.mint(depositer1, depositAmount);
        mock.approve(address(vault2), depositAmount);
        console.logUint(mock.balanceOf(depositer1));
        console.logUint(depositAmount);
        vault2.deposit(depositAmount);
        vm.stopPrank();
        assertEq(weth.balanceOf(address(vault)), uint256(depositAmount));
        assertVaultState(
            StateChecker(1, 0, 0, uint128(depositAmount), 0, 0, 0, 0, 0)
        );
        vm.prank(manager1);
        // none should be locked up yet
        contractKeeper.rollRound("WETH", 0);
        vm.prank(manager2);
        contractKeeper.rollRound("MOCK", 0);
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
        assertEq(weth.balanceOf(manager1), depositAmount);
        assertEq(mock.balanceOf(address(vault2)), 0);
        assertEq(mock.balanceOf(address(contractKeeper)), 0);
        assertEq(mock.balanceOf(manager2), depositAmount);

        vm.startPrank(manager1);
        weth.approve(address(contractKeeper), depositAmount);
        contractKeeper.rollRound("WETH", depositAmount);
        vm.stopPrank();
        vm.startPrank(manager2);
        mock.approve(address(contractKeeper), depositAmount);
        contractKeeper.rollRound("MOCK", depositAmount);
        vm.stopPrank();

        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(weth.balanceOf(address(contractKeeper)), 0);
        assertEq(weth.balanceOf(manager1), depositAmount);
        assertEq(mock.balanceOf(address(vault2)), 0);
        assertEq(mock.balanceOf(address(contractKeeper)), 0);
        assertEq(mock.balanceOf(manager2), depositAmount);

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

        vm.startPrank(manager1);
        contractKeeper.rollRound("WETH", 0);

        vm.stopPrank();
        vm.prank(depositer1);
        vault.initiateWithdraw(depositAmount - 100);

        vm.startPrank(manager1);
        weth.approve(address(contractKeeper), depositAmount - 100);
        contractKeeper.rollRound("WETH", depositAmount);

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
        assertEq(weth.balanceOf(manager1), 100);
    }
    function test_addVault_existingTicker() public {
        address newVault = address(
            new StreamVault(
                address(weth),
                address(contractKeeper),
                lzEndpoint,
                lzDelegate,
                "NewStreamVault",
                "NSV",
                Vault.VaultParams({
                    decimals: 18,
                    asset: address(weth),
                    minimumSupply: minSupply,
                    cap: vaultCap
                })
            )
        );
        vm.prank(owner);
        vm.expectRevert("VaultKeeper: Vault already exists");
        contractKeeper.addVault("WETH", newVault, manager1);
    }

    function test_removeVault_invalidManager() public {
        vm.prank(depositer1);
        vm.expectRevert("VaultKeeper: Invalid manager");
        contractKeeper.removeVault("WETH");
    }

    function test_transferOwnership_invalidManager() public {
        address newManager = vm.addr(5);
        vm.prank(depositer1);
        vm.expectRevert("VaultKeeper: Invalid manager");
        contractKeeper.transferOwnership("WETH", newManager);
    }

    function test_transferCoordinator_invalidOwner() public {
        address newCoordinator = vm.addr(6);
        vm.prank(depositer1);
        vm.expectRevert("VaultKeeper: Invalid coordinator");
        contractKeeper.transferCoordinator(newCoordinator);
    }

    function test_withdraw_invalidOwner() public {
        uint256 amount = 100 * (10 ** 18);
        vm.prank(depositer1);
        vm.expectRevert("VaultKeeper: Invalid coordinator");
        contractKeeper.withdraw(address(weth), amount);
    }

    function test_addVault() public {
        address newVault = address(
            new StreamVault(
                address(weth),
                address(contractKeeper),
                lzEndpoint,
                lzDelegate,
                "NewStreamVault",
                "NSV",
                Vault.VaultParams({
                    decimals: 18,
                    asset: address(weth),
                    minimumSupply: minSupply,
                    cap: vaultCap
                })
            )
        );
        vm.prank(owner);
        contractKeeper.addVault("NEW", newVault, manager1);
        assertEq(contractKeeper.vaults("NEW"), newVault);
        assertEq(contractKeeper.managers("NEW"), manager1);
    }
    function test_RevertIfNotEnoughToCoverWithdraw(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        vm.prank(manager1);
        contractKeeper.rollRound("WETH", 0);
        vm.prank(depositer1);
        vault.initiateWithdraw(depositAmount - 100);
        weth.mint(manager1, 1 ether);
        vm.startPrank(manager1);
        weth.approve(address(contractKeeper), depositAmount - 101);
        vm.expectRevert();
        contractKeeper.rollRound("WETH", depositAmount);
    }

    function test_removeVault() public {
        vm.prank(manager1);
        contractKeeper.removeVault("WETH");
        assertEq(contractKeeper.vaults("WETH"), address(0));
    }

    function test_transferOwnership() public {
        address newManager = vm.addr(5);
        vm.prank(manager1);
        contractKeeper.transferOwnership("WETH", newManager);
        assertEq(contractKeeper.managers("WETH"), newManager);
    }

    function test_transferCoordinator() public {
        address newCoordinator = vm.addr(6);
        vm.prank(owner);
        contractKeeper.transferCoordinator(newCoordinator);
        assertEq(contractKeeper.coordinator(), newCoordinator);
    }

    function test_withdraw() public {
        uint256 amount = 100 * (10 ** 18);
        weth.mint(address(contractKeeper), amount);
        vm.prank(owner);
        contractKeeper.withdraw(address(weth), amount);
        assertEq(weth.balanceOf(owner), amount);
    }

    function test_rollRound_invalidManager() public {
        vm.prank(depositer1);
        vm.expectRevert("VaultKeeper: Invalid manager");
        contractKeeper.rollRound("WETH", 0);
    }

    function test_rollRound_invalidVault() public {
        vm.prank(manager1);
        vm.expectRevert("VaultKeeper: Invalid manager");
        contractKeeper.rollRound("INVALID", 0);
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
