// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IVat {
  struct Ilk {
    uint256 Art;   // Total Normalised Debt     [wad]
    uint256 rate;  // Accumulated Rates         [ray]
    uint256 spot;  // Price with Safety Margin  [ray]
    uint256 line;  // Debt Ceiling              [rad]
    uint256 dust;  // Urn Debt Floor            [rad]
  }
  struct Urn {
    uint256 ink;   // Locked Collateral  [wad]
    uint256 art;   // Normalised Debt    [wad]
  }

  function ilks(bytes32 ilk) external view returns (Ilk memory);
  function urns(bytes32 ilk, address urn) external view returns (Urn memory);
  
}