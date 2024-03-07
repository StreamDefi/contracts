// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



interface IDssProxyActions {

  function open(
    address manager,
    bytes32 ilk,
    address usr
  ) external returns (uint cdp);

  function lockGemAndDraw(
    address manager,
    address jug,
    address gemJoin,
    address daiJoin,
    uint cdp,
    uint wadC,
    uint wadD,
    bool transferFrom
   ) external;

  function wipeAndFreeGem(
    address manager,
    address gemJoin,
    address daiJoin,
    uint cdp,
    uint wadC,
    uint wadD
  ) external; 

  function lockGem(
    address manager,
    address gemJoin,
    uint cdp,
    uint wad,
    bool transferFrom
  ) external;

  function draw(
    address manager,
    address jug,
    address daiJoin,
    uint cdp,
    uint wad
  ) external;

  
  function wipe(
    address manager,
    address daiJoin,
    uint cdp,
    uint wad
  ) external;

  function freeGem(
    address manager,
    address gemJoin,
    uint cdp,
    uint wad
  )  external;


 



}
