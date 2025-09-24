// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "./lib/SyBase.sol";
// import {IStreamVault} from "./interfaces/IStreamVault.sol";
// import {Vault} from "./lib/Vault.sol";

// contract EthereumXETHPendleSY is SYBase {

//     address public constant ETHEREUM_WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
//     address public constant XETH_ADDRESS = 0x7E586fBaF3084C0be7aB5C82C04FfD7592723153;
//     uint8 public constant XETH_DECIMALS = 18;

//     constructor(
//         string memory _name,
//         string memory _symbol
//     ) SYBase(_name, _symbol, XETH_ADDRESS) {
//     }

//     /*///////////////////////////////////////////////////////////////
//                     DEPOSIT/REDEEM USING BASE TOKENS
//     //////////////////////////////////////////////////////////////*/

//     function _deposit(address, uint256 amountDeposited)
//         internal
//         pure
//         override
//         returns (
//             uint256 /*amountSharesOut*/
//         )
//     {
//        return amountDeposited;
//     }

//     function _redeem(
//         address receiver,
//         address tokenOut,
//         uint256 amountSharesToRedeem
//     )
//         internal
//         override
//         returns (
//             uint256 /*amountTokenOut*/
//         )
//     {
//         _transferOut(tokenOut, receiver, amountSharesToRedeem);
//         return amountSharesToRedeem;
//     }

//     /*///////////////////////////////////////////////////////////////
//                                EXCHANGE-RATE
//     //////////////////////////////////////////////////////////////*/

//     function exchangeRate() public view override returns (uint256) {

//         Vault.VaultState memory vaultState = IStreamVault(XETH_ADDRESS).vaultState();

//         // round is already > 2
//         uint256 sharePrice = IStreamVault(XETH_ADDRESS).roundPricePerShare(vaultState.round - 1);
//         return sharePrice;
//     }

//     /*///////////////////////////////////////////////////////////////
//                 MISC FUNCTIONS FOR METADATA
//     //////////////////////////////////////////////////////////////*/

//     function _previewDeposit(address, uint256 amountTokenToDeposit)
//         internal
//         pure
//         override
//         returns (
//             uint256 /*amountSharesOut*/
//         )
//     {
//         return amountTokenToDeposit;
//     }

//     function _previewRedeem(address, uint256 amountSharesToRedeem)
//         internal
//         pure
//         override
//         returns (
//             uint256 /*amountTokenOut*/
//         )
//     {
//         return amountSharesToRedeem;
//     }

//     function getTokensIn() public view override returns (address[] memory res) {
//         res = new address[](1);
//         res[0] = yieldToken;
//     }

//     function getTokensOut() public view override returns (address[] memory res) {
//         res = new address[](1);
//         res[0] = yieldToken;
//     }

//     function isValidTokenIn(address token) public view override returns (bool) {
//         return token == yieldToken;
//     }

//     function isValidTokenOut(address token) public view override returns (bool) {
//         return token == yieldToken;
//     }

//     function assetInfo()
//         external
//         pure
//         returns (
//             AssetType assetType,
//             address assetAddress,
//             uint8 assetDecimals
//         )
//     {
//         return (AssetType.TOKEN, ETHEREUM_WETH_ADDRESS, 18);
//     }
// }
