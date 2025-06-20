// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/SyBase.sol";
import "./interfaces/IEOFeedAdapter.sol";


contract SonicXUSDPendleSY is SYBase {

    address public constant ETHEREUM_USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant XUSD_ADDRESS = 0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926;
    uint8 public constant XUSD_DECIMALS = 6;
    address public constant XUSD_USD_FEED_ADDRESS = 0x90BD4a5Ef184f41f6083FcC25cB6c3494aEf6e02;
    address public constant USDC_USD_FEED_ADDRESS = 0xB4B5F81aeb1Cd7a39d43a48F5d32A28Af5d6E824;

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

        (, int256 xUSDPrice,,,) = IEOFeedAdapter(XUSD_USD_FEED_ADDRESS).latestRoundData();
        uint8 xUSDPriceDecimals = IEOFeedAdapter(XUSD_USD_FEED_ADDRESS).decimals();
        (, int256 usdcPrice,,,) = IEOFeedAdapter(USDC_USD_FEED_ADDRESS).latestRoundData();
        uint8 usdcPriceDecimals = IEOFeedAdapter(USDC_USD_FEED_ADDRESS).decimals();

        // Convert int256 to uint256 (safe since oracle prices should be positive)
        uint256 xUSDPriceInUSDC = uint256(xUSDPrice) * (10**usdcPriceDecimals) / uint256(usdcPrice);
        return xUSDPriceInUSDC * (10 ** (18 - xUSDPriceDecimals));
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

    function _previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
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
