// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyOFT} from "../src/MyOFT.sol";
import {console2} from "forge-std/console2.sol";

contract SetPeersBaseScript is Script {
    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Arbitrum contracts
        address arbWrapper = 0x884d60A44F6c8483780C6C4f2636195366952E34;
        address arbVault = 0x55b97D28E3df8d1879b581267dF0c2cEeE8505C3;

        // Base contracts
        address baseWrappedOFT = 0x2b82247a9BDA2B72b37e36c7db482abDe7802D31;
        address baseStakedOFT = 0x6242EfAC2E1A85bB9ECFc10895da6e2928C89Fb1;

        // Arbitrum Sepolia EID
        uint32 arbSepolia = 40231;

        vm.startBroadcast(deployerPrivateKey);

        MyOFT baseWrapped = MyOFT(baseWrappedOFT);
        MyOFT baseStaked = MyOFT(baseStakedOFT);

        baseWrapped.setPeer(arbSepolia, addressToBytes32(arbWrapper));
        baseStaked.setPeer(arbSepolia, addressToBytes32(arbVault));

        vm.stopBroadcast();

        console2.log("\nBase Peer Setup Complete:");
        console2.log("-------------------");
        console2.log("Set Arbitrum peer for Wrapped OFT");
        console2.log("Set Arbitrum peer for Staked OFT");
    }
}
