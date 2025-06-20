// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/SyBase.sol";
import {IStreamVault} from "./interfaces/IStreamVault.sol";
import {Vault} from "./lib/Vault.sol";

contract Scaled18EthereumXUSDPendleSY is SYBase {

    address public constant ETHEREUM_USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant XUSD_ADDRESS = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
    uint8 public constant XUSD_DECIMALS = 6;

    constructor(
        string memory _name,
        string memory _symbol,
        address _wrapperFactory
    ) SYBase(_name, _symbol, XUSD_ADDRESS) {
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address, uint256 amountDeposited)
        internal
        pure
        override
        returns (
            uint256 /*amountSharesOut*/
        )
    {
       return amountDeposited;
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
        _transferOut(tokenOut, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
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

    function _previewDeposit(address, uint256 amountTokenToDeposit)
        internal
        pure
        override
        returns (
            uint256 /*amountSharesOut*/
        )
    {
        return amountTokenToDeposit;
    }

    function _previewRedeem(address, uint256 amountSharesToRedeem)
        internal
        pure
        override
        returns (
            uint256 /*amountTokenOut*/
        )
    {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        res = new address[](1);
        res[0] = yieldToken;
    }

    function getTokensOut() public view override returns (address[] memory res) {
        res = new address[](1);
        res[0] = yieldToken;
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldToken;
    }

    function assetInfo()
        external
        pure
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        )
    {
        return (AssetType.TOKEN, ETHEREUM_USDC_ADDRESS, 6);
    }
}
