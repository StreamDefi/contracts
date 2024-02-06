// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {StreamVault} from "../../src/StreamVault.sol";
import {Base} from "../Base.t.sol";

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

contract StreamVaultDepositTest is Test, Base {
    /************************************************
     *  INTERNAL DEPOSIT FOR TESTS
     ***********************************************/

    function test_depositReceiptCreatedForNewDepositer(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        assertDepositReceipt(DepositReceiptChecker(depositer1, 0, 0, 0));

        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, uint104(depositAmount), 0)
        );
    }

    function test_depositRecieptIncreasesWhenDepositingSameRound(
        uint56 depositAmount1,
        uint56 depositAmount2
    ) public {
        vm.assume(depositAmount1 > minSupply);
        vm.assume(depositAmount2 > minSupply);
        vm.deal(depositer1, depositAmount1);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount1}();

        assertEq(weth.balanceOf(address(vault)), depositAmount1);

        assertDepositReceipt(
            DepositReceiptChecker(
                depositer1, // depositer
                1, // round
                depositAmount1, // amount
                0 // unredeemed shares
            )
        );

        assertVaultState(
            StateChecker(
                1, // round
                0, // locked amount
                0, // last lockedAmount
                uint128(depositAmount1), // total pending
                0, // queuedWithdrawShares
                0, // lastQueuedWithdrawAmount
                0, // currentQueuedWithdrawShares
                0, // totalShareSupply
                0 // currentRoundPricePerShare
            )
        );
        vm.deal(depositer1, depositAmount2);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount2}();

        assertEq(
            weth.balanceOf(address(vault)),
            uint256(depositAmount2) + uint256(depositAmount1)
        );
        assertDepositReceipt(
            DepositReceiptChecker(
                depositer1,
                1,
                uint104(depositAmount1) + uint104(depositAmount2),
                0
            )
        );

        assertVaultState(
            StateChecker(
                1, // round
                0, // locked amount
                0, // last lockedAmount
                uint128(depositAmount1) + uint128(depositAmount2), // total pending
                0, // queuedWithdrawShares
                0, // lastQueuedWithdrawAmount
                0, // currentQueuedWithdrawShares
                0, // totalShareSupply
                0 // currentRoundPricePerShare
            )
        );
    }

    function test_RevertIfDepositExceedsCap() public {
        vm.deal(depositer1, vaultCap);
        vm.prank(depositer1);
        vault.depositETH{value: vaultCap}();

        assertEq(weth.balanceOf(address(vault)), vaultCap);

        assertDepositReceipt(
            DepositReceiptChecker(
                depositer1, // depositer
                1, // round
                uint104(vaultCap), // amount
                0 // unredeemed shares
            )
        );

        assertVaultState(
            StateChecker(
                1, // round
                0, // locked amount
                0, // last lockedAmount
                uint128(vaultCap), // total pending
                0, // queuedWithdrawShares
                0, // lastQueuedWithdrawAmount
                0, // currentQueuedWithdrawShares
                0, // totalShareSupply
                0 // currentRoundPricePerShare
            )
        );

        vm.deal(depositer1, 1 ether);
        vm.startPrank(depositer1);
        vm.expectRevert("Exceed cap");
        vault.depositETH{value: 1 ether}();
    }

    function test_RevertIfDepositUnderMinSupply() public {
        vm.startPrank(depositer1);
        vm.expectRevert("Insufficient balance");
        vault.depositETH{value: 0.000001 ether}();
    }

    function test_RevertIfTotalPendingDoesntFit128Bits(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _weth = address(dummyAsset);
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

        vm.startPrank(depositer1);
        vm.deal(depositer1, type(uint128).max);
        vm.expectRevert("Exceed cap");
        vault.depositETH{value: type(uint128).max}();
    }

    function test_vaultStateMaintainedThroughDeposits(
        uint56 depositAmount1,
        uint56 depositAmount2
    ) public {
        vm.assume(depositAmount1 > minSupply);
        vm.assume(depositAmount2 > minSupply);
        vm.deal(depositer1, depositAmount1);
        vm.deal(depositer2, depositAmount2);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount1}();
        vm.prank(depositer2);
        vault.depositETH{value: depositAmount2}();

        assertEq(
            weth.balanceOf(address(vault)),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        // should have zero shares minted
        assertEq(vault.balanceOf(address(vault)), 0);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount1, 0)
        );

        assertDepositReceipt(
            DepositReceiptChecker(depositer2, 1, depositAmount2, 0)
        );

        assertVaultState(
            StateChecker(
                1,
                0,
                0,
                uint128(depositAmount1) + uint128(depositAmount2),
                0,
                0,
                0,
                0,
                0
            )
        );

        vm.prank(keeper);
        vault.rollToNextRound(
            uint256(depositAmount1) + uint256(depositAmount2)
        );

        assertEq(
            weth.balanceOf(keeper),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(
            vault.balanceOf(address(vault)),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        //deposit receipts shouldn't change yet
        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount1, 0)
        );

        assertDepositReceipt(
            DepositReceiptChecker(depositer2, 1, depositAmount2, 0)
        );

        // vault state should change
        assertVaultState(
            StateChecker(
                2,
                uint104(depositAmount1) + uint104(depositAmount2),
                0,
                0,
                0,
                0,
                0,
                uint256(depositAmount1) + uint256(depositAmount2),
                singleShare
            )
        );
    }

    function test_processesDepositFromPrevRound(
        uint56 depositAmount1,
        uint56 depositAmount2
    ) public {
        vm.assume(depositAmount1 > minSupply);
        vm.assume(depositAmount2 > minSupply);
        vm.deal(depositer1, depositAmount1);
        vm.deal(depositer2, depositAmount2);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount1}();
        vm.prank(depositer2);
        vault.depositETH{value: depositAmount2}();

        assertEq(
            weth.balanceOf(address(vault)),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        // should have zero shares minted
        assertEq(vault.balanceOf(address(vault)), 0);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount1, 0)
        );

        assertDepositReceipt(
            DepositReceiptChecker(depositer2, 1, depositAmount2, 0)
        );

        assertVaultState(
            StateChecker(
                1,
                0,
                0,
                uint128(depositAmount1) + uint128(depositAmount2),
                0,
                0,
                0,
                0,
                0
            )
        );

        vm.prank(keeper);
        vault.rollToNextRound(
            uint256(depositAmount1) + uint256(depositAmount2)
        );

        assertEq(
            weth.balanceOf(keeper),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        assertEq(weth.balanceOf(address(vault)), 0);
        assertEq(
            vault.balanceOf(address(vault)),
            uint256(depositAmount1) + uint256(depositAmount2)
        );
        //deposit receipts shouldn't change yet
        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount1, 0)
        );

        assertDepositReceipt(
            DepositReceiptChecker(depositer2, 1, depositAmount2, 0)
        );

        // vault state should change
        assertVaultState(
            StateChecker(
                2,
                uint104(depositAmount1) + uint104(depositAmount2),
                0,
                0,
                0,
                0,
                0,
                uint256(depositAmount1) + uint256(depositAmount2),
                singleShare
            )
        );

        uint256 secondaryDepositAmt = 1 ether;
        vm.deal(depositer1, secondaryDepositAmt);
        vm.deal(depositer2, secondaryDepositAmt);
        vm.prank(depositer1);
        vault.depositETH{value: secondaryDepositAmt}();
        vm.prank(depositer2);
        vault.depositETH{value: secondaryDepositAmt}();

        assertEq(weth.balanceOf(address(vault)), secondaryDepositAmt * 2);

        assertDepositReceipt(
            DepositReceiptChecker(
                depositer1,
                2,
                uint104(secondaryDepositAmt),
                uint128(depositAmount1)
            )
        );

        assertDepositReceipt(
            DepositReceiptChecker(
                depositer2,
                2,
                uint104(secondaryDepositAmt),
                uint128(depositAmount2)
            )
        );

        assertVaultState(
            StateChecker(
                2,
                uint104(depositAmount1) + uint104(depositAmount2),
                0,
                uint128(secondaryDepositAmt * 2),
                0,
                0,
                0,
                uint256(depositAmount1) + uint256(depositAmount2),
                singleShare
            )
        );
    }

    function test_RevertIfOverflowDepositAmt(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _weth = address(dummyAsset);
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
        uint256 depositAmount = uint256(type(uint104).max) + uint256(1 ether);
        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vm.expectRevert();
        vault.depositETH{value: depositAmount}();
    }

    /************************************************
     *  EXTERNAL DEPOSIT TESTS
     ***********************************************/

    function test_RevertIfAmountNotGreaterThanZero() public {
        vm.startPrank(depositer1);
        vm.expectRevert("!amount");
        vault.deposit(0);
    }

    function test_vaultReceivesToken(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        dummyAsset.mint(depositer1, depositAmount);

        vm.startPrank(depositer1);
        dummyAsset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount);

        assertEq(dummyAsset.balanceOf(address(vault)), depositAmount);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
    }

    function test_RevertsIfInsufficientBalanceToken(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        dummyAsset.mint(depositer1, depositAmount - 1);

        vm.startPrank(depositer1);
        dummyAsset.approve(address(vault), depositAmount - 1);
        vm.expectRevert();
        vault.deposit(depositAmount);
    }

    function test_RevertIfDepositingWrongAsset(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        weth.mint(depositer1, depositAmount);
        vm.startPrank(depositer1);
        weth.approve(address(vault), depositAmount);
        vm.expectRevert();
        vault.deposit(depositAmount);
    }

    /************************************************
     *  EXTERNAL DEPOSIT ETH FOR TESTS
     ***********************************************/
    function test_vaultReceivesDepositETHForOnCreditorBehalf(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        uint256 preCreditorBalance = address(depositer1).balance;
        vm.startPrank(depositer2);
        vm.deal(depositer2, depositAmount);
        vault.depositETHFor{value: depositAmount}(depositer1);

        uint256 postCreditorBalance = address(depositer1).balance;
        assertEq(preCreditorBalance, postCreditorBalance);

        assertEq(weth.balanceOf(address(vault)), depositAmount);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );

        assertDepositReceipt(DepositReceiptChecker(depositer2, 0, 0, 0));
    }

    function test_RevertIfDepositETHForAmtIsNotGreaterThanZero() public {
        vm.startPrank(depositer2);
        vm.expectRevert("!value");
        vault.depositETHFor{value: 0}(depositer1);
    }

    function test_RevertIfDepositETHForZeroAdr(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);

        vm.deal(depositer2, depositAmount);

        vm.startPrank(depositer2);
        dummyAsset.approve(address(vault), depositAmount);
        vm.expectRevert("!creditor");
        vault.depositFor(depositAmount, address(0));
    }

    function test_RevertsIfVaultAssetIsntWETHInDepositForETH(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        vm.deal(depositer2, depositAmount);
        vm.startPrank(depositer2);
        vm.expectRevert("!WETH");
        vault.depositETHFor{value: depositAmount}(depositer1);
    }

    function test_RevertsIfInsufficientBalanceETHInDepositFor(
        uint56 depositAmount
    ) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer2, depositAmount - 1);
        vm.startPrank(depositer2);
        vm.expectRevert();
        vault.depositETHFor{value: depositAmount}(depositer1);
    }

    /************************************************
     *  EXTERNAL DEPOSIT FOR TESTS
     ***********************************************/

    function test_vaultReceivesDepositForTokenOnCreditorBehalf(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        dummyAsset.mint(depositer2, depositAmount);

        uint256 preCreditorBalance = dummyAsset.balanceOf(depositer1);

        vm.startPrank(depositer2);
        dummyAsset.approve(address(vault), depositAmount);
        vault.depositFor(depositAmount, depositer1);

        uint256 postCreditorBalance = dummyAsset.balanceOf(depositer1);
        assertEq(preCreditorBalance, postCreditorBalance);

        assertEq(dummyAsset.balanceOf(address(vault)), depositAmount);

        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
    }

    function test_RevertIfDepositForAmtIsNotGreaterThanZero(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        vm.startPrank(depositer2);

        vm.expectRevert("!amount");
        vault.depositFor(0, depositer1);
    }

    function test_RevertIfDepositForZeroAdr(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        dummyAsset.mint(depositer2, depositAmount);

        vm.startPrank(depositer2);
        dummyAsset.approve(address(vault), depositAmount);
        vm.expectRevert("!creditor");
        vault.depositFor(depositAmount, address(0));
    }

    function test_RevertsIfInsufficientBalanceTokenInDepositFor(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        dummyAsset.mint(depositer2, depositAmount - 1);

        vm.startPrank(depositer2);
        dummyAsset.approve(address(vault), depositAmount - 1);
        vm.expectRevert();
        vault.depositFor(depositAmount, depositer1);
    }

    function test_RevertIfDepositingWrongAssetInDepositFor(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        _vaultParams.minimumSupply = minSupply;
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        weth.mint(depositer2, depositAmount);
        vm.startPrank(depositer2);
        weth.approve(address(vault), depositAmount);
        vm.expectRevert();
        vault.depositFor(depositAmount, depositer1);
    }

    /************************************************
     *  EXTERNAL DEPOSIT ETH TESTS
     ***********************************************/

    function test_RevertsIfVaultAssetIsntWETH(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams,
        uint56 depositAmount
    ) public {
        _vaultParams.cap = type(uint104).max;
        _vaultParams.asset = address(dummyAsset);
        vm.assume(_keeper != address(0));
        vm.assume(_vaultParams.cap > 0);
        vm.assume(_vaultParams.asset != address(0));
        vm.assume(depositAmount > minSupply);

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            _keeper,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        vm.deal(depositer1, depositAmount);
        vm.startPrank(depositer1);
        vm.expectRevert("!WETH");
        vault.depositETH{value: depositAmount}();
    }

    function test_RevertIfValueNotGreaterThanZero() public {
        vm.startPrank(depositer1);
        vm.expectRevert("!value");
        vault.depositETH{value: 0}();
    }

    function test_vaultReceivesWETH(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount);
        vm.prank(depositer1);
        vault.depositETH{value: depositAmount}();

        assertEq(weth.balanceOf(address(vault)), depositAmount);
        assertDepositReceipt(
            DepositReceiptChecker(depositer1, 1, depositAmount, 0)
        );
    }

    function test_RevertsIfInsufficientBalanceETH(uint56 depositAmount) public {
        vm.assume(depositAmount > minSupply);
        vm.deal(depositer1, depositAmount - 1);
        vm.startPrank(depositer1);
        vm.expectRevert();
        vault.depositETH{value: depositAmount}();
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
}
