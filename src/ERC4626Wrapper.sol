// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ShareMath} from "./lib/ShareMath.sol";
import {Vault} from "./lib/Vault.sol";
import {IStreamVault} from "./interfaces/IStreamVault.sol";

contract StreamVaultERCWrapper {
    using ShareMath for Vault.StakeReceipt;

    address public vaultContract;
    uint256 internal constant PLACEHOLDER_UINT = 1;

    error PreviewRedeemFailed();
    error AddressMustBeNonZero();
    
    // #############################################
    // CONSTRUCTOR & INITIALIZATION
    // #############################################

    constructor(
        address _vaultContract
    ) {
        if (_vaultContract == address(0)) revert AddressMustBeNonZero();

        vaultContract = _vaultContract;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets) {

        if (shares <= PLACEHOLDER_UINT) {
            return 0;
        }

        Vault.VaultParams memory vaultParams = IStreamVault(vaultContract).vaultParams();
        Vault.VaultState memory vaultState = IStreamVault(vaultContract).vaultState();

        // round is already > 2
        uint256 pricePerShare = IStreamVault(vaultContract).roundPricePerShare(vaultState.round - 1);

        return ShareMath.sharesToAsset(
            shares,
            pricePerShare,
            vaultParams.decimals
        );
    }
}