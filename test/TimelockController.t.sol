// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TimelockController} from "../src/TimelockController.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {Vault} from "../src/lib/Vault.sol";
import {TestToken} from "../src/TestToken.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract TimelockControllerTest is Test, TestHelperOz5 {
    TimelockController public timelock;
    StreamVault public vault;
    StableWrapper public wrapper;
    
    address public owner = makeAddr("owner");
    address public keeper = makeAddr("keeper");
    address public lzDelegate = makeAddr("lzDelegate");
    uint256 public constant DELAY = 20;
    uint32 private aEid = 1;
    
    function setUp() public override {
        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);
        
        // Deploy timelock with owner as the owner
        timelock = new TimelockController(owner, DELAY);
        
        // Deploy mock WBTC
        TestToken wbtc = new TestToken("Wrapped BTC", "WBTC", 8);

        vm.startPrank(owner);

        // Deploy wrapper
        wrapper = new StableWrapper(
            address(wbtc),
            "Stream BTC",
            "streamBTC",
            8,
            keeper,
            address(endpoints[aEid]),
            lzDelegate
        );

        // Setup vault params
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 8,
            cap: 100 * 10**8,
            minimumSupply: 1 * 10**4
        });

        // Deploy vault
        vault = new StreamVault(
            "Staked Stream BTC",
            "xBTC",
            address(wrapper),
            address(endpoints[aEid]),
            lzDelegate,
            vaultParams
        );

        wrapper.setKeeper(address(vault));
        wrapper.transferOwnership(address(timelock));
        vault.transferOwnership(address(timelock));

        vm.stopPrank();
    }
    
    function test_ImmediateExecution() public {
        vm.startPrank(owner);  // Start acting as owner
        
        // Test rollToNextRound immediate execution
        bytes memory data = abi.encodeWithSelector(
            vault.rollToNextRound.selector,
            1e18,
            true
        );
        timelock.executeImmediate(address(vault), data);
        
        // Test processWithdrawals immediate execution
        data = abi.encodeWithSelector(
            wrapper.processWithdrawals.selector
        );
        timelock.executeImmediate(address(wrapper), data);
        
        vm.stopPrank();
    }
    
    function test_DelayedExecution() public {
        vm.startPrank(owner);

        // Test a normal delayed function (e.g., setKeeper)
        address newKeeper = makeAddr("newKeeper");
        bytes memory data = abi.encodeWithSelector(
            wrapper.setKeeper.selector,
            newKeeper
        );
        
        // Try immediate - should fail
        vm.expectRevert(TimelockController.FunctionMustBeImmediate.selector);
        timelock.executeImmediate(address(wrapper), data);
        
        // Schedule properly
        timelock.schedule(address(wrapper), data, bytes32(0));
        
        // Try execute too early - should fail
        vm.expectRevert(TimelockController.OperationNotReady.selector);
        timelock.executeDelayed(address(wrapper), data, bytes32(0));
        
        // Wait delay period
        vm.warp(block.timestamp + DELAY);
        
        // Now should succeed
        timelock.executeDelayed(address(wrapper), data, bytes32(0));
        
        // Verify keeper was updated
        assertEq(wrapper.keeper(), newKeeper);
        vm.stopPrank();
    }
    
    function test_ChangingDelay() public {
        vm.startPrank(owner);
        // First queue the new delay
        timelock.queueNewDelay(30);
        
        // Try to update too early
        vm.expectRevert(TimelockController.DelayChangeNotReady.selector);
        timelock.updateDelay();
        
        // Wait for delay
        vm.warp(block.timestamp + DELAY);
        
        // Now update should work
        timelock.updateDelay();
        assertEq(timelock.minDelay(), 30);
        vm.stopPrank();
    }
    
    function test_DelayedVaultFunction() public {
        vm.startPrank(owner);
        // Try to change vault params
        Vault.VaultParams memory newParams = Vault.VaultParams({
            decimals: 8,
            cap: 200 * 10**8,  // 200 BTC cap
            minimumSupply: 1 * 10**4
        });
        
        bytes memory data = abi.encodeWithSelector(
            vault.setVaultParams.selector,
            newParams
        );
        
        // Schedule the change
        timelock.schedule(address(vault), data, bytes32(0));
        
        // Try execute too early
        vm.expectRevert(TimelockController.OperationNotReady.selector);
        timelock.executeDelayed(address(vault), data, bytes32(0));
        
        // Wait for delay
        vm.warp(block.timestamp + DELAY);
        
        // Now execute should work
        timelock.executeDelayed(address(vault), data, bytes32(0));
        
        // Verify params were updated
        assertEq(vault.cap(), 200 * 10**8);
        vm.stopPrank();
    }
} 