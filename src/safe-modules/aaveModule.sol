// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveV3Module is Ownable {
    /************************************************
     *  STATE
     ***********************************************/
    address public safe;
    mapping(address asset => uint256 irm) public irms;
    address public aave;

    /************************************************
     *  INIT
     ***********************************************/
    constructor(
        address _safe,
        address _multisig,
        address _aave,
        uint256[] memory _irms,
        address[] memory _assets
    ) Ownable(_multisig) {
        require(_irms.length == _assets.length, "Invalid input");
        aave = _aave;
        safe = _safe;
        for (uint i = 0; i < _irms.length; ) {
            irms[_assets[i]] = _irms[i];
            unchecked {
                ++i;
            }
        }
    }
}
