// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title - MakerLongLooper
 * @notice - This contract is responsible for opening leveraged margin long positions on maker
 */
contract MakerLongLooper is Ownable{
    constructor () Ownable(msg.sender) {}
}