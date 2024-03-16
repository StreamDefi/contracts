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
        StreamVault btcVault = StreamVault(
            payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E)
        );
        StreamVault wethVault = StreamVault(
            payable(0x2a2f84e9AfE7b39146CDaF068b06b84EE23892c2)
        );
        StreamVault usdcVault = StreamVault(
            payable(0xf3b466F09ef476E311Ce275407Cfb09a8D8De3a7)
        );

        VaultKeeper keeper = VaultKeeper(
            0xdfFB08C3366854b7baCfd6281757F9cda152994c
        );

        string[] memory tickers = new string[](2);
        tickers[0] = "WBTC";
        tickers[1] = "USDC";
        //   tickers[2] = "WETH";

        uint256[] memory lockedBalances = new uint256[](2);
        lockedBalances[0] = 532340000;
        lockedBalances[1] = 1698868000000;
        //  lockedBalances[2] = 130764300000000000000;
        console.logString("------BEFORE_-------");

        console.logString("Price per share of BTC Vault");
        uint256 pricePerShare = btcVault.pricePerShare();
        console.logUint(pricePerShare);

        console.log("Price per share of WETH Vault");
        pricePerShare = wethVault.pricePerShare();
        console.logUint(pricePerShare);

        console.log("Price per share of USDC Vault");
        pricePerShare = usdcVault.pricePerShare();
        console.logUint(pricePerShare);

        keeper.rollRound(tickers, lockedBalances);

        console.log("Price per share of BTC Vault");
        pricePerShare = btcVault.pricePerShare();
        console.logUint(pricePerShare);

        console.log("Price per share of WETH Vault");
        pricePerShare = wethVault.pricePerShare();
        console.logUint(pricePerShare);

        console.log("Price per share of USDC Vault");
        pricePerShare = usdcVault.pricePerShare();
        console.logUint(pricePerShare);

        vm.stopPrank();
    }
}
