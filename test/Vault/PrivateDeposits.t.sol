// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {StreamVault} from "../../src/StreamVault.sol";
import {Base} from "../Base.t.sol";
import "forge-std/console.sol";

contract StreamVaultPrivateDepositTest is Test, Base {
  function test_RevertIfPublicDepositWhenNotPublic() public {
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.deal(depositer1, depositAmount);
    vm.startPrank(depositer1);
    vm.expectRevert("!public");
    vault.depositETH{value: depositAmount}();
  }

  function test_PrivateDepositETH() public {
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.deal(depositer1, depositAmount);
    vm.startPrank(depositer1);
    vault.privateDepositETH{value: depositAmount}();
    assertEq(vault.totalPending(), depositAmount);
  }


  function deployVault() public {
    vault = new StreamVault(
      address(weth),
      address(keeper),
      "StreamVault",
      "SV",
      Vault.VaultParams({
        decimals: 18,
        asset: address(weth),
        minimumSupply: minSupply,
        cap: vaultCap
      })
    );
  }

}