// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployStreamVault is Script {
    address public weth = vm.envAddress("SEPOLIA_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // comment out if mainnet and replace with actual token
        MockERC20 token = new MockERC20("MOCK TOKEN", "MOCK6");
        token.mint(keeper, 100000 ether);
        VaultKeeper vaultKeeper = new VaultKeeper();
        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 6,
            asset: address(token),
            minimumSupply: uint56(10),
            cap: uint104(100000000000)
        });

        StreamVault vault = new StreamVault(weth, address(vaultKeeper), "StreamVaultTest", "SVT", vaultParams);
        vaultKeeper.addVault("MOCK6", address(vault));
        vm.stopBroadcast();
    }
}
