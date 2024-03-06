// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DepositHandler
 * @dev Handles deposit in arbitrary erc-20 into dedicated vaults
 */


 /*
  Depositor state
  - mapping vault ticker --> address
  - mapping depositor address --> vault ticker --> position struct
  - mapping token --> boolean (for token whitelist)

  Functions
  - Add/Remove vaults (owner gated)
  - Add/Remove token whitelist
  - deposit (params: token, vault)s
  - depositFor (params: token, deposit for addy, vault)
  - reedem
  - initiate withdraw
  - complete withdraw (params: receive token)

  Implementation:
  = will need some form of DEX swap integrated to swap arbitrary tokens
  - Position struct:
    {
      depositor: address
      token deposited: address
      vault deposited: addrss
      amount deposited: uint
    }
 */
contract DepositHandler {
  
}