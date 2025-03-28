// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "../lib/Vault.sol";

/**
 * @title IStableWrapper
 * @notice Interface for the StableWrapper contract
 */
interface IStreamVault {

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function roundPricePerShare(uint256) external view returns (uint256);
}
