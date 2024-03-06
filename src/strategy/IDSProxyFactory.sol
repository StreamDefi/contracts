// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDSProxy} from "./IDSProxy.sol";
interface IDSProxyFactory {
   function build() external returns (IDSProxy proxy);
}