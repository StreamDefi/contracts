// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DepositStreamVault is Script {
    function run() public {
        // build proof for certain address
        bytes32[] memory proof = new bytes32[](6);
        proof[0] = 0x35edacbc12443cff9b001f5e1c6678e0dee34be1fbd9627d2dc056dc542ac1a7;
        proof[1] = 0xdac1fad5344e2782fb9e99bb7a7800fe07fda92fa96f2f7b3fadabc206f0c613;
        proof[2] = 0xc972b1303675d066dc2343b49ad4d987d11ac803eecb70cba9c176f041da661a;
        proof[3] = 0xee70d0483fcf5a5a946b9b3b10ce14a6817ae80ad47ea7d525f0e2901c51ca6b;
        proof[4] = 0xcc541f5663a113ff67bb881f2a253bf9bc6ea220c26d7359ab864b5e4c5ec531;
        proof[5] = 0x6f0177c5461bce124583ff96cf780172531a0ee3f1b89ace4bb370dc70e7f0a1;

        // simulate calls from
        vm.startPrank(0x99655b07F321B6B5a2809f43e1A143d7f7a1634f);
        StreamVault vault = StreamVault(
            payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E)
        );
        // simulate depositing
        vault.privateDeposit(451051400, proof);




    }
}
