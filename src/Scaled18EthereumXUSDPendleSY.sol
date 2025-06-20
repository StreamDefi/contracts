// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/SyBase.sol";
import "./interfaces/IPDecimalsWrapperFactory.sol";
import "./interfaces/IPDecimalsWrapper.sol";
import {IStreamVault} from "./interfaces/IStreamVault.sol";
import {Vault} from "./lib/Vault.sol";

contract Scaled18EthereumXUSDPendleSY is SYBase {

    address public constant XUSD_ADDRESS = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    uint8 public constant XUSD_DECIMALS = 6;

    constructor(
        string memory _name,
        string memory _symbol,
        address _wrapperFactory
    ) SYBase(_name, _symbol, IPDecimalsWrapperFactory(_wrapperFactory).getOrCreate(XUSD_ADDRESS, 18)) {
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        override
        returns (
            uint256 /*amountSharesOut*/
        )
    {
        if (tokenIn == yieldToken) {
            return amountDeposited;
        } else {
            return IPDecimalsWrapper(yieldToken).wrap(amountDeposited);
        }
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    )
        internal
        override
        returns (
            uint256 /*amountTokenOut*/
        )
    {
        if (tokenOut == yieldToken) {
            _transferOut(tokenOut, receiver, amountSharesToRedeem);
            return amountSharesToRedeem;
        } else {
            uint256 xUSDAmount = IPDecimalsWrapper(yieldToken).unwrap(amountSharesToRedeem);
            _transferOut(tokenOut, receiver, xUSDAmount);
            return xUSDAmount;
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view override returns (uint256) {

        Vault.VaultState memory vaultState = IStreamVault(XUSD_ADDRESS).vaultState();

        // round is already > 2
        uint256 sharePrice = IStreamVault(XUSD_ADDRESS).roundPricePerShare(vaultState.round - 1);
        return sharePrice * (10 ** (18-XUSD_DECIMALS));
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        internal
        view
        override
        returns (
            uint256 /*amountSharesOut*/
        )
    {
        if (tokenIn == yieldToken) {
            return amountTokenToDeposit;
        } else {
            return IPDecimalsWrapper(yieldToken).rawToWrapped(amountTokenToDeposit);
        }
    }

    function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        view
        override
        returns (
            uint256 /*amountTokenOut*/
        )
    {
        if (tokenOut == yieldToken) {
            return amountSharesToRedeem;
        } else {
            return IPDecimalsWrapper(yieldToken).wrappedToRaw(amountSharesToRedeem);
        }
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(XUSD_ADDRESS, yieldToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(XUSD_ADDRESS, yieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == XUSD_ADDRESS || token == yieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == XUSD_ADDRESS || token == yieldToken;
    }

    function assetInfo()
        external
        view
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        )
    {
        return (AssetType.TOKEN, yieldToken, 18);
    }
}
