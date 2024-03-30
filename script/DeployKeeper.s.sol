// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract DeployKeeper is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        StreamVault btcVault = StreamVault(
            payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E)
        );
        StreamVault wethVault = StreamVault(
            payable(0x2a2f84e9AfE7b39146CDaF068b06b84EE23892c2)
        );
        StreamVault usdcVault = StreamVault(
            payable(0xf3b466F09ef476E311Ce275407Cfb09a8D8De3a7)
        );

        VaultKeeper keeper = new VaultKeeper();

        keeper.addVault("WBTC", address(btcVault));
        keeper.addVault("WETH", address(wethVault));
        keeper.addVault("USDC", address(usdcVault));

        keeper.transferOwnership(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);

        vm.stopBroadcast();
    }
}
