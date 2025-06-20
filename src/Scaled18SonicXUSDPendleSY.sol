// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./lib/SyBase.sol";
import "./interfaces/IPDecimalsWrapperFactory.sol";
import "./interfaces/IPDecimalsWrapper.sol";
import "./interfaces/IEOFeedAdapter.sol";


contract Scaled18SonicXUSDPendleSY is SYBase {

    address public constant XUSD_ADDRESS = 0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926;
    uint8 public constant XUSD_DECIMALS = 6;
    address public constant XUSD_USD_FEED_ADDRESS = 0x90BD4a5Ef184f41f6083FcC25cB6c3494aEf6e02;
    address public constant USDC_USD_FEED_ADDRESS = 0xB4B5F81aeb1Cd7a39d43a48F5d32A28Af5d6E824;

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
