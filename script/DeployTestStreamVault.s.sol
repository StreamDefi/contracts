// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployTestStreamVault is Script {
    address public weth = vm.envAddress("BLAST_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // comment out if mainnet and replace with actual token
        // MockERC20 token =  new MockERC20("MOCK TOKEN", "MOCK");
        // token.mint(keeper, 100000 ether);
        // 1. deploy the keeper contract
        address[] memory vaults = new address[](0);
        string[] memory tickers = new string[](0);
        address[] memory managers = new address[](0);
        VaultKeeper vaultKeeper = new VaultKeeper(tickers, managers, vaults);

        // 2. prep vault params
        Vault.VaultParams memory vaultParamsUSDC = Vault.VaultParams({
            decimals: 18,
            asset: vm.envAddress("BLAST_WETH"),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        // 3. deploy vaults
        StreamVault USDCVault = new StreamVault(
            weth,
            address(vaultKeeper),
            "Stream Hodl Wrapped ETH",
            "sHodlwETH",
            vaultParamsUSDC
        );

        // 4. add vaults to keeper
        vaultKeeper.addVault("WETH", address(USDCVault), keeper);

        vm.stopBroadcast();
    }
}
