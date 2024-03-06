// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployStreamVault is Script {
    address public weth = vm.envAddress("ETHEREUM_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // // // comment out if mainnet and replace with actual token
        // // MockERC20 token = new MockERC20("MOCK TOKEN", "MOCK6");
        // // token.mint(keeper, 100000 ether);
        // // 1. deploy the keeper contract
        VaultKeeper vaultKeeper = new VaultKeeper();

        // 2. prep vault params
        Vault.VaultParams memory vaultParamsUSDC = Vault.VaultParams({
            decimals: 6,
            asset: address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsBTC = Vault.VaultParams({
            decimals: 8,
            asset: address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599),
            minimumSupply: uint56(1000),
            cap: uint104(1000000000000000000000000)
        });

        Vault.VaultParams memory vaultParamsETH = Vault.VaultParams({
            decimals: 18,
            asset: weth,
            minimumSupply: uint56(100000000),
            cap: uint104(1000000000000000000000000)
        });

        // // 3. deploy vaults
        StreamVault USDCVault = new StreamVault(weth, address(vaultKeeper), "Stream LevUSDC", "sLevUSDC", vaultParamsUSDC);
        StreamVault BTCVault = new StreamVault(weth, address(vaultKeeper), "Stream HodlwBTC", "sHodlwBTC", vaultParamsBTC);
        StreamVault ETHVault = new StreamVault(weth, address(vaultKeeper), "Stream HodlwETH", "sHodlwETH", vaultParamsETH);

     

        // 4. add vaults to keeper
        vaultKeeper.addVault("USDC", address(USDCVault));
        vaultKeeper.addVault("WBTC", address(BTCVault));
        vaultKeeper.addVault("WETH", address(ETHVault));

       
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");
        console.logBytes32(merkleRoot);

        // 5. add merkle roots to vaults
        USDCVault.setMerkleRoot(merkleRoot);
        BTCVault.setMerkleRoot(merkleRoot);
        ETHVault.setMerkleRoot(merkleRoot);

        vaultKeeper.transferOwnership(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);
        
    
        vm.stopBroadcast();
    }
}
