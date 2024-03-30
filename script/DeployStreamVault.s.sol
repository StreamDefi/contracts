// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployStreamVault is Script {
    address public weth = vm.envAddress("AVALANCHE_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // // // comment out if mainnet and replace with actual token
        // // MockERC20 token = new MockERC20("MOCK TOKEN", "MOCK6");
        // // token.mint(keeper, 100000 ether);
        // // 1. deploy the keeper contract

        VaultKeeper vaultKeeper = new VaultKeeper();

        console.logString("Deployed VaultKeeper");

        // // 2. prep vault params
        Vault.VaultParams memory vaultParamsUSDC = Vault.VaultParams({
            decimals: 6,
            asset: vm.envAddress("ARBITRUM_USDC"),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsBTC = Vault.VaultParams({
            decimals: 8,
            asset: vm.envAddress("ARBITRUM_WBTC"),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsETH = Vault.VaultParams({
            decimals: 18,
            asset: weth,
            minimumSupply: uint56(100000000),
            cap: uint104(1000000000000000000000000)
        });

        // 3. deploy vaults
        StreamVault USDCVault = new StreamVault(
            weth,
            address(vaultKeeper),
            "Stream LevUSDC",
            "sLevUSDC",
            vaultParamsUSDC
        );

        console.logString("Deployed USDC Vault");

        StreamVault BTCVault = new StreamVault(
            weth,
            address(vaultKeeper),
            "Stream HodlwBTC",
            "sHodlwBTC",
            vaultParamsBTC
        );

        console.logString("Deployed WBTC Vault");

        StreamVault ETHVault = new StreamVault(
            weth,
            address(vaultKeeper),
            "Stream HodlwETH",
            "sHodlwETH",
            vaultParamsETH
        );

        console.logString("Deployed WETH Vault");

        // 4. add vaults to keeper
        vaultKeeper.addVault("USDC", address(USDCVault));
        console.logString("Added USDC Vault to Keeper");
        vaultKeeper.addVault("WBTC", address(BTCVault));
        console.logString("Added WBTC Vault to Keeper");
        vaultKeeper.addVault("WETH", address(ETHVault));
        console.logString("Added WETH Vault to Keeper");

        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");

        // 5. add merkle roots to vaults
        USDCVault.setMerkleRoot(merkleRoot);
        console.logString("Set USDC Merkle Root");
        BTCVault.setMerkleRoot(merkleRoot);
        console.logString("Set WBTC Merkle Root");
        ETHVault.setMerkleRoot(merkleRoot);
        console.logString("Set WETH Merkle Root");

        vaultKeeper.transferOwnership(
            0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444
        );
        USDCVault.transferOwnership(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);
        BTCVault.transferOwnership(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);
        ETHVault.transferOwnership(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);

        console.logString("Transferred Ownership");

        vm.stopBroadcast();
    }
}
