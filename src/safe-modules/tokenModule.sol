// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GnosisSafe} from "../interfaces/GnosisSafe.sol";

/**
 * @title TokenModule
 * @notice A gnosis safe module to interact with whitelisted ERC20 tokens
 */
contract TokenModule is Ownable {
    /************************************************
     *  STATE
     ***********************************************/
    address public safe;
    mapping(address token => bool canTrade) public tokens;
    mapping(address receiver => bool canReceive) public receivers;
    mapping(address operator => bool canOperate) public operators;

    constructor(
        address _safe,
        address _multisig,
        address[] memory _tokens,
        address[] memory _receivers,
        address[] memory _operators
    ) Ownable(_multisig) {
        safe = _safe;
        for (uint i = 0; i < _tokens.length; ) {
            tokens[_tokens[i]] = true;
            unchecked {
                ++i;
            }
        }
        for (uint i = 0; i < _receivers.length; ) {
            receivers[_receivers[i]] = true;
            unchecked {
                ++i;
            }
        }
        for (uint i = 0; i < _operators.length; ) {
            operators[_operators[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /************************************************
     *  TOKEN INTERACTIONS
     ***********************************************/

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyOwner {
        require(tokens[_token], "Invalid token");
        require(operators[_spender], "Invalid spender");
        _approveToken(_token, _spender, _amount);
    }

    function approveTokens(
        address[] memory _tokens,
        address[] memory _spenders,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            _tokens.length == _spenders.length &&
                _spenders.length == _amounts.length,
            "Invalid input"
        );
        for (uint i = 0; i < _tokens.length; ) {
            require(tokens[_tokens[i]], "Invalid token");
            require(operators[_spenders[i]], "Invalid spender");
            _approveToken(_tokens[i], _spenders[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(tokens[_token], "Invalid token");
        require(receivers[_to], "Invalid receiver");
        bytes memory txData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            _to,
            _amount
        );
        _makeSafeInteraction(_token, 0, txData);
    }

    function transferTokens(
        address[] memory _tokens,
        address[] memory _tos,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            _tokens.length == _tos.length && _tos.length == _amounts.length,
            "Invalid input"
        );
        for (uint i = 0; i < _tokens.length; ) {
            require(tokens[_tokens[i]], "Invalid token");
            require(receivers[_tos[i]], "Invalid receiver");
            bytes memory txData = abi.encodeWithSelector(
                IERC20.transfer.selector,
                _tos[i],
                _amounts[i]
            );
            _makeSafeInteraction(_tokens[i], 0, txData);
            unchecked {
                ++i;
            }
        }
    }

    function transferFromToken(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(tokens[_token], "Invalid token");
        bytes memory txData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        _makeSafeInteraction(_token, 0, txData);
    }
    /************************************************
     *  WHITELIST INTERACTIONS
     ***********************************************/
    function modifyTokenList(address _token, bool _canTrade) external {
        require(msg.sender == safe, "Only safe can modify markets");
        tokens[_token] = _canTrade;
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
