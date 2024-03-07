// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPipLike {
  function peek() external returns (bytes32, bool);
}
interface ISpotter {
  struct Ilk {
    IPipLike pip;
    uint256 mat;
  }

  function ilks(bytes32) external view returns (Ilk memory);
}