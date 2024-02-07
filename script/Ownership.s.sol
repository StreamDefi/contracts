// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract TransferOwnership is Script {
    address public weth = vm.envAddress("ETHEREUM_WETH");
    address public keeper = vm.envAddress("VAULT_KEEPER");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        VaultKeeper vaultKeeper = VaultKeeper(0x7012DaAB8D34a6f415b2EAac3b75565592d1B09e);
  
        address owner = vm.envAddress("VAULT_OWNER");

        StreamVault USDCVault = StreamVault(payable(0xf3b466F09ef476E311Ce275407Cfb09a8D8De3a7));
        StreamVault BTCVault = StreamVault(payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E));
        StreamVault ETHVault = StreamVault(payable(0x2a2f84e9AfE7b39146CDaF068b06b84EE23892c2));

        USDCVault.transferOwnership(owner);
        BTCVault.transferOwnership(owner);
        ETHVault.transferOwnership(owner);
        vaultKeeper.transferOwnership(owner);
    
        vm.stopBroadcast();
    }
}
