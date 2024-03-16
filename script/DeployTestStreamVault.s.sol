// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployTestStreamVault is Script {
    address public weth = vm.envAddress("SEPOLIA_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // comment out if mainnet and replace with actual token
        MockERC20 tokenUSDC = MockERC20(
            0xaEe9D3D9fcA9A463f94003B3e7959f81688D4484
        );
        // tokenUSDC.mint(keeper, 100000 ether);

        MockERC20 tokenWBTC = MockERC20(
            0xfCb171e19Fe666a83cF1E9fc7097C7C0FaA54491
        );
        // tokenWBTC.mint(keeper, 100000 ether);
        // 1. deploy the keeper contract
        VaultKeeper vaultKeeper = VaultKeeper(
            0x554032E181a0205e8dD802e9E711e4CB01A41899
        );

        // 2. prep vault params
        Vault.VaultParams memory vaultParamsUSDC = Vault.VaultParams({
            decimals: 6,
            asset: address(tokenUSDC),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsWBTC = Vault.VaultParams({
            decimals: 8,
            asset: address(tokenWBTC),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsWETH = Vault.VaultParams({
            decimals: 18,
            asset: weth,
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        // 3. deploy vaults
        // StreamVault USDCVault = new StreamVault(
        //     weth,
        //     address(vaultKeeper),
        //     "Stream Leveraged USDC",
        //     "LevUSDC",
        //     vaultParamsUSDC
        // );

        StreamVault USDCVault = StreamVault(
            payable(0x68473A4971fc30Bc8e9399EbC59B11bdBf2C1FC8)
        );

        StreamVault WBTCVault = StreamVault(
            payable(0x28ddC632d87FDAAB45151005F3C98170629f6293)
        );

        StreamVault WETHVault = StreamVault(
            payable(0x80cc3A074c14DA83e0Bdd48b32C4406Ef363A098)
        );

        USDCVault.setPublic(true);
        tokenUSDC.approve(address(USDCVault), 100000 ether);
        USDCVault.deposit(10450000000);

        // 4. add vaults to keeper
        // vaultKeeper.addVault("USDC", address(USDCVault));
        // vaultKeeper.addVault("WBTC", address(WBTCVault));
        // vaultKeeper.addVault("WETH", address(WETHVault));

        vm.stopBroadcast();
    }
}
