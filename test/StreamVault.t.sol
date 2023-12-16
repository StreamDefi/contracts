// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "forge-std/Test.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {Vault} from "../src/lib/Vault.sol";

contract StreamVaultTest is Test {
    StreamVault vault;
    MockERC20 weth;

    address depositer1 = vm.addr(1);
    address depositer2 = vm.addr(2);
    address depositer3 = vm.addr(3);
    address depositer4 = vm.addr(4);
    address depositer5 = vm.addr(5);
    address depositer6 = vm.addr(6);
    address depositer7 = vm.addr(7);
    address depositer8 = vm.addr(8);
    address depositer9 = vm.addr(9);
    address depositer10 = vm.addr(10);

    address[] depositors = [
        depositer1,
        depositer2,
        depositer3,
        depositer4,
        depositer5,
        depositer6,
        depositer7,
        depositer8,
        depositer9,
        depositer10
    ];

    address keeper = vm.addr(11);
    address owner = vm.addr(12);

    function setUp() public {
        weth = new MockERC20("wrapped ether", "WETH");
        for (uint256 i = 0; i < depositors.length; i++) {
            weth.mint(depositors[i], 1000 * (10 ** 18));
        }

        Vault.VaultParams memory vaultParams = Vault.VaultParams({
            decimals: 18,
            asset: address(weth),
            minimumSupply: uint56(1),
            cap: uint104(10000000 * (10 ** 18))
        });

        vm.prank(owner);
        vault = new StreamVault(
            address(weth),
            keeper,
            "StreamVault",
            "SV",
            vaultParams
        );
    }
}
