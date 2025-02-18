// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StableWrapper} from "../src/StableWrapper.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {console2} from "forge-std/console2.sol";

contract SetPeersArbitrumScript is Script {
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Arbitrum contracts
        address arbWrapper = 0x6eAf19b2FC24552925dB245F9Ff613157a7dbb4C;
        address arbVault = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;

        // Base contracts
        address baseWrappedOFT = 0x212187708d01A63bcbE2F59553537de407a5621D;
        address baseStakedOFT = 0xa791082be08B890792c558F1292Ac4a2Dad21920;

        // Base Sepolia EID
        uint32 baseSepolia = 30184;

        vm.startBroadcast(deployerPrivateKey);

        StableWrapper wrapper = StableWrapper(arbWrapper);
        StreamVault vault = StreamVault(arbVault);

        wrapper.setPeer(baseSepolia, addressToBytes32(baseWrappedOFT));
        vault.setPeer(baseSepolia, addressToBytes32(baseStakedOFT));

        vm.stopBroadcast();

        console2.log("\nArbitrum Peer Setup Complete:");
        console2.log("-------------------");
        console2.log("Set Base peer for StableWrapper");
        console2.log("Set Base peer for StreamVault");
    }
}