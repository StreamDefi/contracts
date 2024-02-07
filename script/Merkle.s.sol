// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Merkle} from "lib/murky/src/Merkle.sol";
import "forge-std/console.sol";

contract FormMerkleTree is Script {
    function run() public {
      Merkle m = new Merkle();
      bytes32[] memory data = new bytes32[](6);
      data[0] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST1")));
      data[1] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST2")));
      data[2] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST3")));
      data[3] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST4")));
      data[4] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST5")));
      data[5] = keccak256(abi.encodePacked(vm.envAddress("WHITELIST6")));


      // Get Root, Proof, and Verify
      bytes32 root = m.getRoot(data);
      bytes32[] memory proof = m.getProof(data, 5);
      console.logBytes32(root);
      for (uint256 i = 0; i < proof.length; i++) {
        console.logBytes32(proof[i]);
      }
    }
}
