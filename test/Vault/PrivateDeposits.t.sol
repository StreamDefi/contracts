// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "../../src/lib/Vault.sol";
import {StreamVault} from "../../src/StreamVault.sol";
import {Base} from "../Base.t.sol";
import "forge-std/console.sol";
import {Merkle} from "lib/murky/src/Merkle.sol";

contract StreamVaultPrivateDepositTest is Test, Base {

  bytes32 public root;
  function test_RevertIfPublicDepositWhenNotPublic() public {
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.deal(depositer1, depositAmount);
    vm.startPrank(depositer1);
    vm.expectRevert("!public");
    vault.depositETH{value: depositAmount}();
  }

  function test_PrivateDepositETH() public {
    bytes32[] memory proof = formMerkleTree(0);
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.deal(depositer1, depositAmount);
    vm.startPrank(depositer1);
    vault.privateDepositETH{value: depositAmount}(proof);
    assertEq(vault.totalPending(), depositAmount);
  }

  function test_PrivateDeposit() public {
    bytes32[] memory proof = formMerkleTree(0);
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.deal(depositer1, depositAmount);
    vm.startPrank(depositer1);
    weth.approve(address(vault), depositAmount);
    vault.privateDeposit(depositAmount, proof);
    assertEq(vault.totalPending(), depositAmount);
  }

  function test_RevertIfInvalidWhitelist() public {
    bytes32[] memory proof = formMerkleTree(0);
    deployVault();
    uint256 depositAmount = 1 ether;
    vm.startPrank(depositer5);
    vm.expectRevert("Invalid proof");
    vault.privateDepositETH{value: depositAmount}(proof);
  }


  function deployVault() public {
    vm.startPrank(owner);
    vault = new StreamVault(
      address(weth),
      address(keeper),
      "StreamVault",
      "SV",
      Vault.VaultParams({
        decimals:uint8(_decimals),
        asset: address(weth),
        minimumSupply: minSupply,
        cap: vaultCap
      })
    );
    vault.setMerkleRoot(root);
    
  }

  function formMerkleTree(uint256 depositer) public returns (bytes32[] memory proof) {
    Merkle m = new Merkle();
    bytes32[] memory data = new bytes32[](4);
    data[0] = keccak256(abi.encodePacked(depositer1));
    data[1] = keccak256(abi.encodePacked(depositer2));
    data[2] = keccak256(abi.encodePacked(depositer3));
    data[3] = keccak256(abi.encodePacked(depositer4));
    // Get Root, Proof, and Verify
    root = m.getRoot(data);
    proof = m.getProof(data, depositer);
  }


}