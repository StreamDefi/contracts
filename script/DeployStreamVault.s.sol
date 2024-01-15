// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";

contract DeployStreamVault is Script {
    // weth address on sepolia testnet
    address public weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address public keeper = 0x84fEC48Dc7C2E4e39a43456747a880a9C85230F1;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: weth,
            minimumSupply: uint56(1),
            cap: uint104(10000000 * (10 ** 18))
        });

        new StreamVault(weth, keeper, "StreamVaultTest", "SVT", vaultParams);
    }
}
