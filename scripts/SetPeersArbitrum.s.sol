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
        address arbWrapper = 0x6FbB289DD177D3F23673B04ba29fe611ad6707dc;
        address arbVault = 0x8A31D2D10f34aAF24A2c48713e213266bc01c68b;

        // Base contracts
        address baseWrappedOFT = 0xF8fD2b6226384f307E72f6Ac6A276D4A0549B5C6;
        address baseStakedOFT = 0x308645E8f0F7345E3d60de29b2F74Fee92A387F6;

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