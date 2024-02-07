// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DepositStreamVault is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        StreamVault vault = StreamVault(
            payable(0x2938A650e9Bb6B0FD6eCb6a0584F6150a8edB20C)
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x858cfe3ff9ea7ea7544d1d074419b079499c5c24147036b10ad5011b23c8ff31;
        proof[1] = 0xa5a63ffde85d9898fb9ba1328f94a348cb5cfca61f6eaf8a57a2826e9b2d6f89;

        vault.privateDeposit(0.28491 ether, proof);
        vm.stopBroadcast();
    }
}
