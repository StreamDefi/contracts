// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {StableWrapper} from "../../src/StableWrapper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Base} from "./Base.t.sol";

/************************************************
 * KEEPER FUNCS
 ***********************************************/
contract StableWrapperKeeperFuncsTest is Base {
    function test_RevertIfAdvanceToEpochCallerIsNotKeeper(
        address _caller
    ) public {
        vm.assume(_caller != keeper);
        vm.assume(_caller != address(0));

        vm.startPrank(_caller);
        vm.expectRevert(StableWrapper.NotKeeper.selector);
        stableWrapper.advanceEpoch();
        vm.stopPrank();
    }

    function test_AdvanceEpochAdvancedEpochByOne() public {
        assertEpoch(1);
        vm.prank(keeper);
        stableWrapper.advanceEpoch();
        assertEpoch(2);
    }

    function test_RevertIfSetKeeperNotCalledByKeeper(address _caller) public {
        vm.assume(_caller != keeper);
        vm.assume(_caller != address(0));
        vm.startPrank(_caller);
        vm.expectRevert(StableWrapper.NotKeeper.selector);
        stableWrapper.setKeeper(vm.addr(1001));
        assertEq(stableWrapper.keeper(), keeper);
    }

    function test_RevertIfSetKeeperSetsAddressZero() public {
        vm.startPrank(keeper);
        vm.expectRevert(StableWrapper.AddressMustBeNonZero.selector);
        stableWrapper.setKeeper(address(0));
        assertEq(stableWrapper.keeper(), keeper);
    }

    function test_RevertIfsetAllowIndependenceNotCalledByKeeper(
        address _caller
    ) public {
        vm.assume(_caller != keeper);
        vm.assume(_caller != address(0));
        vm.startPrank(_caller);
        vm.expectRevert(StableWrapper.NotKeeper.selector);
        stableWrapper.setAllowIndependence(true);
        assertEq(stableWrapper.allowIndependence(), false);
    }

    function test_SuccessfullSetAllowIndependence() public {
        assertEq(stableWrapper.allowIndependence(), false);
        vm.prank(keeper);
        stableWrapper.setAllowIndependence(true);
        assertEq(stableWrapper.allowIndependence(), true);
    }

    function test_RevertIfTransferAssetWithAmountZero() public {
        vm.startPrank(keeper);
        vm.expectRevert(StableWrapper.AmountMustBeGreaterThanZero.selector);
        stableWrapper.transferAsset(keeper, 0, address(0));
        vm.stopPrank();
    }
    function test_RevertIfKeeperDoesNotCallTransferAsset(
        address _caller
    ) public {
        vm.assume(_caller != keeper);
        vm.assume(_caller != address(0));
        vm.startPrank(_caller);
        vm.expectRevert(StableWrapper.NotKeeper.selector);
        stableWrapper.transferAsset(keeper, 0, address(0));
        vm.stopPrank();
    }

    function test_SuccessfullTransferAsset() public {
        vm.prank(depositor1);
        usdc.transfer(address(stableWrapper), 100);
        assertEq(usdc.balanceOf(address(stableWrapper)), 100);
        vm.prank(keeper);
        stableWrapper.transferAsset(keeper, 100, address(usdc));
        assertEq(usdc.balanceOf(keeper), 100);
        assertEq(usdc.balanceOf(address(stableWrapper)), 0);
    }

    function test_RevertIfPermissionedMintCallerIsNotOwner(
        address _caller
    ) public {
        vm.assume(_caller != owner);
        vm.assume(_caller != address(0));

        vm.startPrank(_caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                _caller
            )
        );
        stableWrapper.permissionedMint(address(1), 100);
        vm.stopPrank();
    }

    function test_SuccessfulPermissionedMint(uint256 _amount) public {
        vm.assume(_amount != 0);
        address recipient = address(1);
        uint256 amount = _amount;

        vm.prank(owner);
        stableWrapper.permissionedMint(recipient, _amount);

        assertEq(stableWrapper.balanceOf(recipient), _amount);
        assertEq(stableWrapper.totalSupply(), _amount);
    }

    function test_RevertIfPermissionedBurnCallerIsNotOwner(
        address _caller
    ) public {
        vm.assume(_caller != owner);
        vm.assume(_caller != address(0));

        vm.startPrank(_caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                _caller
            )
        );
        stableWrapper.permissionedBurn(address(1), 100);
        vm.stopPrank();
    }

    function test_SuccessfulPermissionedBurn() public {
        address burner = address(1);
        uint256 amount = 100;

        vm.prank(owner);
        stableWrapper.permissionedMint(burner, amount);
        assertEq(stableWrapper.balanceOf(burner), amount);

        vm.prank(owner);
        stableWrapper.permissionedBurn(burner, amount);
        assertEq(stableWrapper.balanceOf(burner), 0);
    }

    function test_RevertIfSetDecimalsCallerIsNotKeeper(address _caller) public {
        vm.assume(_caller != keeper);
        vm.assume(_caller != address(0));

        vm.startPrank(_caller);
        vm.expectRevert(StableWrapper.NotKeeper.selector);
        stableWrapper.setDecimals(18);
        vm.stopPrank();
    }

    function test_SuccessfulSetDecimals(uint8 _newDecimals) public {
        vm.prank(keeper);
        stableWrapper.setDecimals(_newDecimals);

        assertEq(stableWrapper.decimals(), _newDecimals);
        assertEq(stableWrapper.underlyingDecimals(), _newDecimals);
    }
}
