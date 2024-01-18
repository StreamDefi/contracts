// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployStreamVault is Script {
    address public weth = vm.envAddress("BERACHAIN_WBERA");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // comment out if mainnet and replace with actual token
        // MockERC20 token = new MockERC20("MOCK TOKEN", "MOCK");
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: weth,
            minimumSupply: uint56(0.000001 ether),
            cap: uint104(100000 ether)
        });

        new StreamVault(weth, keeper, "StreamVaultTest", "SVT", vaultParams);
    }
}
