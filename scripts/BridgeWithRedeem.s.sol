// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {SendParam, MessagingFee, MessagingReceipt, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract BridgeWithRedeemScript is Script {
    using OptionsBuilder for bytes;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Configuration - Update these values as needed
        address stakedUSDContractAddress = 0xE2Fc85BfB48C4cF147921fBE110cf92Ef9f26F94;
        uint32 destinationEID = 30383;
        uint256 bridgeAmount = 10000000;
        uint256 gasFee = 178757056857880;

        StreamVault vault = StreamVault(payable(stakedUSDContractAddress));

        // vm.startBroadcast(deployerPrivateKey);
        vm.startPrank(0x70e1b787A5D677a5906AccCF0B4F387b8Bb1B5C3);

        // Build LayerZero options for the destination chain
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(2000000, 0); // 2M gas limit, 0 msg.value

        // Construct SendParam for bridging
        SendParam memory sendParam = SendParam(
            destinationEID,
            bytes32(uint256(uint160(deployer))), // recipient as bytes32
            bridgeAmount, // amount to bridge
            bridgeAmount, // minimum amount (no slippage)
            options, // LayerZero options
            "", // no compose msg
            "" // no oft cmd
        );

        // Construct MessagingFee
        MessagingFee memory messagingFee = MessagingFee(gasFee, 0);

        console2.log("=== Bridge With Redeem Transaction ===");
        console2.log("Staked USD Contract:", stakedUSDContractAddress);
        console2.log("Destination EID:", destinationEID);
        console2.log("Bridge Amount:", bridgeAmount);
        console2.log("Gas Fee:", gasFee);
        console2.log("Sender/Recipient:", deployer);

        // Execute bridgeWithRedeem
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = vault.bridgeWithRedeem{value: gasFee}(
            sendParam,
            messagingFee,
            payable(deployer) // refund address
        );

        console2.log("\n=== Transaction Results ===");
        console2.log("Message GUID:", vm.toString(msgReceipt.guid));
        console2.log("Message Nonce:", msgReceipt.nonce);
        console2.log("Message Fee (Native):", msgReceipt.fee.nativeFee);
        console2.log("Message Fee (LZ Token):", msgReceipt.fee.lzTokenFee);
        console2.log("Amount Sent (credit):", oftReceipt.amountSentLD);
        console2.log("Amount Received (debit):", oftReceipt.amountReceivedLD);

        vm.stopPrank();
        // vm.stopBroadcast();

        console2.log("\n=== Transaction Complete ===");
        console2.log("Bridge with redeem executed successfully!");
    }
}