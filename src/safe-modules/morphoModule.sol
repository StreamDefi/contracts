// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMorphoBase} from "morpho-blue/src/interfaces/IMorpho.sol";
import {MarketParams} from "morpho-blue/src/interfaces/IMorpho.sol";
import {GnosisSafe} from "../interfaces/GnosisSafe.sol";

/**
 * @title MorphoBlueModule
 * @notice A gnosis safe module to interface with morpho blue markets
 */
contract MorphoBlueModule is Ownable {
    /************************************************
     *  STATE
     ***********************************************/
    address public safe;
    mapping(uint id => MarketParams) public morphoMarkets;
    address public morphoBlue;

    /************************************************
     *  INIT
     ***********************************************/
    constructor(
        address _safe,
        address _multisig,
        address _morphoBlue,
        MarketParams[] memory _morphoMarkets
    ) Ownable(_multisig) {
        morphoBlue = _morphoBlue;
        safe = _safe;
        for (uint i = 0; i < _morphoMarkets.length; ) {
            morphoMarkets[i] = _morphoMarkets[i];
            unchecked {
                ++i;
            }
        }
    }

    /************************************************
     *  MORPHO INTERACTIONS
     ***********************************************/
    function morphoSupply(uint256 _amount, uint256 _market) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MarketParams memory market = morphoMarkets[_market];

        _approveToken(market.loanToken, morphoBlue, _amount);
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.supply.selector,
            market,
            _amount,
            0,
            safe,
            "0x"
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    function morphoWithdraw(
        uint256 _shares,
        uint256 _market
    ) external onlyOwner {
        require(_shares > 0, "Invalid shares");
        MarketParams memory market = morphoMarkets[_market];
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.withdraw.selector,
            market,
            0,
            _shares,
            safe,
            safe
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    function morphoBorrow(uint256 _amount, uint256 _market) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MarketParams memory market = morphoMarkets[_market];
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.borrow.selector,
            market,
            _amount,
            0,
            safe,
            safe
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    function morphoSupplyCollateral(
        uint256 _amount,
        uint256 _market
    ) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MarketParams memory market = morphoMarkets[_market];
        _approveToken(market.collateralToken, morphoBlue, _amount);
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.supplyCollateral.selector,
            market,
            _amount,
            safe,
            "0x"
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    function morphoWithdrawCollateral(
        uint256 _amount,
        uint256 _market
    ) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MarketParams memory market = morphoMarkets[_market];
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.withdrawCollateral.selector,
            market,
            _amount,
            safe,
            safe
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    function morphoRepay(uint256 _amount, uint256 _market) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        MarketParams memory market = morphoMarkets[_market];

        _approveToken(market.loanToken, morphoBlue, _amount);
        bytes memory txData = abi.encodeWithSelector(
            IMorphoBase.repay.selector,
            market,
            _amount,
            0,
            safe,
            "0x"
        );

        _makeSafeInteraction(morphoBlue, 0, txData);
    }

    /************************************************
     *  WHITELIST INTERACTIONS
     ***********************************************/
    function modifyMorphoMarket(
        uint256 _market,
        MarketParams memory _params
    ) external {
        require(msg.sender == safe, "Only safe can modify markets");
        morphoMarkets[_market] = _params;
    }

    /************************************************
     *  GENERAL
     ***********************************************/

    function _makeSafeInteraction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        bool success = GnosisSafe(safe).execTransactionFromModule(
            _to,
            _value,
            _data,
            GnosisSafe.Operation.Call
        );
        require(success, "Safe interaction failed");
    }

    function _approveToken(
        address _token,
        address _operator,
        uint _amount
    ) internal {
        bytes memory txData = abi.encodeWithSelector(
            IERC20.approve.selector,
            _operator,
            _amount
        );
        _makeSafeInteraction(_token, 0, txData);
    }

    receive() external payable {}
}
