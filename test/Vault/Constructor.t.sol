// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {StreamVault} from "../../src/StreamVault.sol";
import {Base} from "../Base.t.sol";

/*
  TESTS
  =====
  - constructor
*/

/*
  TESTS
  =====
  - internal deposit for
  - external deposit
  - external deposit for 
  - external deposit ETH
  - external deposit ETH for
  - single deposit simulation
  - multi deposit simulation
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

contract StreamVaultConstructorTest is Test, Base {
    /************************************************
     *  CONSTRUCTOR TESTS
     ***********************************************/

    function test_initializesCorrectly(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_weth != address(0));
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));

        vm.prank(owner);
        vault = new StreamVault(
            _weth,
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        (uint8 decimals, address asset, uint56 _minSupply, uint104 cap) = vault
            .vaultParams();

        assertEq(vault.WETH(), _weth);
        assertEq(vault.keeper(), _keeper);
        assertEq(decimals, _vaultParams.decimals);
        assertEq(asset, address(dummyAsset));
        assertEq(_minSupply, _vaultParams.minimumSupply);
        assertEq(cap, _vaultParams.cap);

        (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares
        ) = vault.vaultState();

        assertEq(round, 1);
        assertEq(lockedAmount, 0);
        assertEq(totalPending, 0);
        assertEq(queuedWithdrawShares, 0);
        assertEq(lastLockedAmount, 0);

        assertEq(vault.name(), _tokenName);
        assertEq(vault.symbol(), _tokenSymbol);
        assertEq(vault.owner(), owner);
    }

    function test_RevertIfWrappedNativeTokenIsZeroAdr(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.asset = address(dummyAsset);
        _weth = address(0);
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));

        vm.startPrank(owner);
        vm.expectRevert("!_weth");
        vault = new StreamVault(
            _weth,
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        vm.stopPrank();
    }

    function test_RevertIfKeeperIsZeroAdr(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_weth != address(0));
        _keeper = address(0);
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));

        vm.startPrank(owner);
        vm.expectRevert("!_keeper");
        vault = new StreamVault(
            _weth,
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        vm.stopPrank();
    }

    function test_RevertIfCapIsZero(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_weth != address(0));
        vm.assume(_keeper != address(0));
        _vaultParams.cap = 0;
        vm.assume(_vaultParams.asset != address(0));

        vm.startPrank(owner);
        vm.expectRevert("!_cap");
        vault = new StreamVault(
            _weth,
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        vm.stopPrank();
    }

    function test_RevertIfAssetIsZeroAdr(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_weth != address(0));
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        _vaultParams.asset = address(0);

        vm.startPrank(owner);
        vm.expectRevert("!_asset");
        vault = new StreamVault(
            _weth,
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        vm.stopPrank();
    }
}
