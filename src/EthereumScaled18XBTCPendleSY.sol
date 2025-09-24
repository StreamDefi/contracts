// pragma solidity ^0.8.20;

// import "./lib/SyBase.sol";
// import "./interfaces/IPDecimalsWrapperFactory.sol";
// import "./interfaces/IPDecimalsWrapper.sol";
// import {IStreamVault} from "./interfaces/IStreamVault.sol";
// import {Vault} from "./lib/Vault.sol";

// contract EthereumScaled18XBTCPendleSY is SYBase {


//     address public constant XBTC_ADDRESS = 0x12fd502e2052CaFB41eccC5B596023d9978057d6;
//     address public constant WBTC_ADDRESS = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;
//     uint8 public constant XBTC_DECIMALS = 8;

//     address public immutable WBTCWrapper;

//     constructor(
//         string memory _name,
//         string memory _symbol,
//         address _wrapperFactory
//     ) SYBase(_name, _symbol, IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(XBTC_ADDRESS, 18)) {
//         WBTCWrapper = IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(WBTC_ADDRESS, 18);
//     }

//     /*///////////////////////////////////////////////////////////////
//                     DEPOSIT/REDEEM USING BASE TOKENS
//     //////////////////////////////////////////////////////////////*/

//     function _deposit(address tokenIn, uint256 amountDeposited)
//         internal

//         override
//         returns (
//             uint256 /*amountSharesOut*/
//         )
//     {
//         if (tokenIn == yieldToken) {
//             return amountDeposited;
//         } else {
//             return IPDecimalsWrapper(yieldToken).wrap(amountDeposited);
//         }
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
//         if (tokenOut == yieldToken) {
//             _transferOut(tokenOut, receiver, amountSharesToRedeem);
//             return amountSharesToRedeem;
//         } else {
//             uint256 xBTCAmount = IPDecimalsWrapper(yieldToken).unwrap(amountSharesToRedeem);
//             _transferOut(tokenOut, receiver, xBTCAmount);
//             return xBTCAmount;
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                                EXCHANGE-RATE
//     //////////////////////////////////////////////////////////////*/

//     function exchangeRate() public view override returns (uint256) {

//         Vault.VaultState memory vaultState = IStreamVault(XBTC_ADDRESS).vaultState();

//         // round is already > 2
//         uint256 sharePrice = IStreamVault(XBTC_ADDRESS).roundPricePerShare(vaultState.round - 1);
//         return sharePrice * (10 ** (18-XBTC_DECIMALS));
//     }

//     /*///////////////////////////////////////////////////////////////
//                 MISC FUNCTIONS FOR METADATA
//     //////////////////////////////////////////////////////////////*/

//     function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
//         internal
//         view
//         override
//         returns (
//             uint256 /*amountSharesOut*/
//         )
//     {
//         if (tokenIn == yieldToken) {
//             return amountTokenToDeposit;
//         } else {
//             return IPDecimalsWrapper(yieldToken).rawToWrapped(amountTokenToDeposit);
//         }
//     }

//     function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
//         internal
//         view
//         override
//         returns (
//             uint256 /*amountTokenOut*/
//         )
//     {
//         if (tokenOut == yieldToken) {
//             return amountSharesToRedeem;
//         } else {
//             return IPDecimalsWrapper(yieldToken).wrappedToRaw(amountSharesToRedeem);
//         }
//     }

//     function getTokensIn() public view override returns (address[] memory res) {
//         return ArrayLib.create(XBTC_ADDRESS, yieldToken);

//     }

//     function getTokensOut() public view override returns (address[] memory res) {
//         return ArrayLib.create(XBTC_ADDRESS, yieldToken);

//     }

//     function isValidTokenIn(address token) public view override returns (bool) {
//         return token == XBTC_ADDRESS || token == yieldToken;
//     }

//     function isValidTokenOut(address token) public view override returns (bool) {
//         return token == XBTC_ADDRESS || token == yieldToken;
//     }

//     function assetInfo()
//         external
//         view
//         returns (
//             AssetType assetType,
//             address assetAddress,
//             uint8 assetDecimals
//         )
//     {
//         return (AssetType.TOKEN, WBTCWrapper, 18);
//     }
// }