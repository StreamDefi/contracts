// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract TestRollRound is Script {
    function run() public {
    
        vm.startPrank(0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444);
        StreamVault vault = StreamVault(
            payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E)
        );

        VaultKeeper keeper = VaultKeeper(
            0xdfFB08C3366854b7baCfd6281757F9cda152994c
        );

        string[] memory tickers = new string[](1);
        tickers[0] = "WBTC";

        uint256[] memory lockedBalances = new uint256[](1);
        lockedBalances[0] = 31029807;
        keeper.rollRound(tickers, lockedBalances);
        
        uint256 pricePerShare = vault.pricePerShare();
        console.logUint(pricePerShare);

        vm.stopPrank();
    }
}
