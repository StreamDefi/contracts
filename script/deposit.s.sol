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
            payable(0x936e81256aEaB09ef2028452D907f3DB64bDF682)
        );
        vault.deposit(0.28491 ether);
    }
}
