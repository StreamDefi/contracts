// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract TestBridgeScript is Script {
    using OptionsBuilder for bytes;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        StreamVault vault = StreamVault(
            payable(0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94)
        );

        vm.startBroadcast(deployerPrivateKey);

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(2000000, 0);

        SendParam memory sendParam = SendParam(
            30332, // BASE_SEPOLIA_EID
            bytes32(uint256(uint160(deployer))), // recipient as bytes32
            1e6, // amount
            1e6, // amount (no slippage)
            options, // options
            "", // no compose msg
            "" // no oft cmd
        );

        // Skip quoteSend entirely and just try to send with hardcoded fee
        vault.send{value: 0.01 ether}(
            sendParam,
            MessagingFee(0.01 ether, 0),
            payable(deployer)
        );

        vm.stopBroadcast();
    }
}
