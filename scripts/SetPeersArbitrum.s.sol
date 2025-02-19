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
        address arbWrapper = 0x05F47d7CbB0F3d7f988E442E8C1401685D2CAbE0;
        address arbVault = 0x12fd502e2052CaFB41eccC5B596023d9978057d6;

        // Base contracts
        address baseWrappedOFT = 0x8A31D2D10f34aAF24A2c48713e213266bc01c68b;
        address baseStakedOFT = 0x09Aed31D66903C8295129aebCBc45a32E9244a1f;

        // Base Sepolia EID
        uint32 baseSepolia = 30184;

        vm.startBroadcast(deployerPrivateKey);

        StableWrapper wrapper = StableWrapper(payable(arbWrapper));
        StreamVault vault = StreamVault(payable(arbVault));

        wrapper.setPeer(baseSepolia, addressToBytes32(baseWrappedOFT));
        vault.setPeer(baseSepolia, addressToBytes32(baseStakedOFT));

        vm.stopBroadcast();

        console2.log("\nArbitrum Peer Setup Complete:");
        console2.log("-------------------");
        console2.log("Set Base peer for StableWrapper");
        console2.log("Set Base peer for StreamVault");
    }
}