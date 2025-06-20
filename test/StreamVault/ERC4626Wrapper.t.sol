// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from "./Base.t.sol";
import {StreamVaultERCWrapper} from "../../src/ERC4626Wrapper.sol";
import {IStreamVault} from "../../src/interfaces/IStreamVault.sol";
import {Vault} from "../../src/lib/Vault.sol";

contract StreamVaultERCWrapperTest is Base {
    StreamVaultERCWrapper public wrapper;

    function setUp() public {
        wrapper = new StreamVaultERCWrapper(address(streamVault));
    }

    /************************************************
     *  PREVIEW REDEEM TESTS
     ***********************************************/

    function test_PreviewRedeemReturnsZeroForZeroShares() public {
        uint256 assets = wrapper.previewRedeem(0);
        assertEq(assets, 0);
    }

    function test_PreviewRedeemReturnsZeroForOneShare() public {
        uint256 assets = wrapper.previewRedeem(1);
        assertEq(assets, 0);
    }

    function test_PreviewRedeemReturnsCorrectAmount(uint104 _amount) public {
        vm.assume(_amount >= minSupply && _amount <= startingBal);
        stakeAssets(depositor1, depositor1, _amount);

        (Vault.VaultParams memory params, Vault.VaultState memory state) = getVaultData();
        uint256 expectedAssets = ShareMath.sharesToAsset(
            _amount,
            streamVault.roundPricePerShare(state.round - 1),
            params.decimals
        );

        uint256 assets = wrapper.previewRedeem(_amount);
        assertEq(assets, expectedAssets);
    }

    function test_PreviewRedeemDoesNotRevert(uint104 _amount) public {
        vm.assume(_amount >= minSupply && _amount <= startingBal);
        stakeAssets(depositor1, depositor1, _amount);

        wrapper.previewRedeem(_amount);
    }

    /************************************************
     *  CONSTRUCTOR TESTS
     ***********************************************/

    function test_RevertIfVaultContractIsZeroAddress() public {
        vm.expectRevert(StreamVaultERCWrapper.AddressMustBeNonZero.selector);
        new StreamVaultERCWrapper(address(0));
    }

    function test_SuccessfulConstruction() public {
        StreamVaultERCWrapper newWrapper = new StreamVaultERCWrapper(address(streamVault));
        assertEq(address(newWrapper.vaultContract()), address(streamVault));
    }

    /************************************************
     *  HELPER FUNCTIONS
     ***********************************************/

    function getVaultData() internal view returns (Vault.VaultParams memory, Vault.VaultState memory) {
        return (
            streamVault.vaultParams(),
            streamVault.vaultState()
        );
    }
}
