// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICDPManager {
  function owns(uint cdpId) external view returns (address);
  function vat() external view returns (address);
  function ilks(uint cdpId) external view returns (bytes32);
  function urns(uint cdpId) external view returns (address);
}