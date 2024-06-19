// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {GnosisSafe} from "../interfaces/GnosisSafe.sol";

/**
 * @title SparkV3Module
 * @notice A gnosis safe module to interface with spark V3 markets
 */
contract SparkModule is Ownable {
    /************************************************
     *  STATE
     ***********************************************/
    address public safe;
    mapping(address asset => uint256 irm) public irms;
    address public spark;

    /************************************************
     *  INIT
     ***********************************************/
    constructor(
        address _safe,
        address _multisig,
        address _spark,
        uint256[] memory _irms,
        address[] memory _assets
    ) Ownable(_multisig) {
        require(_irms.length == _assets.length, "Invalid input");
        spark = _spark;
        safe = _safe;
        for (uint i = 0; i < _irms.length; ) {
            irms[_assets[i]] = _irms[i];
            unchecked {
                ++i;
            }
        }
    }

    /************************************************
     *  SPARK INTERACTIONS
     ***********************************************/

    function sparkSupply(address _asset, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(irms[_asset] != 0, "Invalid asset");

        _approveToken(_asset, spark, _amount);
        bytes memory txData = abi.encodeWithSelector(
            IPool.supply.selector,
            _asset,
            _amount,
            safe,
            0
        );

        _makeSafeInteraction(spark, 0, txData);
    }

    function sparkBorrow(address _asset, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        uint256 irm = irms[_asset];
        require(irm != 0, "Invalid asset");

        bytes memory txData = abi.encodeWithSelector(
            IPool.borrow.selector,
            _asset,
            _amount,
            irm,
            0,
            safe
        );

        _makeSafeInteraction(spark, 0, txData);
    }

    function sparkRepay(address _asset, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        uint256 irm = irms[_asset];
        require(irm != 0, "Invalid asset");

        _approveToken(_asset, spark, _amount);
        bytes memory txData = abi.encodeWithSelector(
            IPool.repay.selector,
            _asset,
            _amount,
            irm,
            safe
        );

        _makeSafeInteraction(spark, 0, txData);
    }

    function sparkWithdraw(address _asset, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(irms[_asset] != 0, "Invalid asset");

        bytes memory txData = abi.encodeWithSelector(
            IPool.withdraw.selector,
            _asset,
            _amount,
            safe
        );

        _makeSafeInteraction(spark, 0, txData);
    }

    /************************************************
     *  WHITELIST INTERACTIONS
     ***********************************************/
    function modifySparkMarket(address _asset, uint256 _irm) external {
        require(msg.sender == safe, "Only safe can modify markets");
        irms[_asset] = _irm;
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
}
