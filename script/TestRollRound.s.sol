// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
import "forge-std/Script.sol";
import {StreamVault} from "../src/StreamVault.sol";
import {Vault} from "../src/lib/Vault.sol";
import {VaultKeeper} from "../src/VaultKeeper.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract TestRollRound is Script {
    function run() public {
        address owner = 0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444;

        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        address btcFunder = 0x77134cbC06cB00b66F4c7e623D5fdBF6777635EC;
        address ethFunder = 0x267ed5f71EE47D3E45Bb1569Aa37889a2d10f91e;
        address usdcFunder = 0xD6153F5af5679a75cC85D8974463545181f48772;

        // fund the owner
        // vm.prank(btcFunder);
        // MockERC20(wbtc).transfer(owner, 80010825);
        // vm.prank(ethFunder);
        // MockERC20(weth).transfer(owner,106357795589174640000);
        // vm.prank(usdcFunder);
        // MockERC20(usdc).transfer(owner, 1168819493115);
    
        vm.startPrank(owner);
        // keeper contract
        VaultKeeper keeper = VaultKeeper(
            0xdfFB08C3366854b7baCfd6281757F9cda152994c
        );

        // string[] memory wbtcTicker = new string[](1);
        // wbtcTicker[0] = "WBTC";

        // string[] memory wethTicker = new string[](1);
        // wethTicker[0] = "WETH";

        // string[] memory usdcTicker = new string[](1);
        // usdcTicker[0] = "USDC";

        // uint256[] memory lockedBalancesWBTC = new uint256[](1);
        // lockedBalancesWBTC[0] = 80359991;

        // uint256[] memory lockedBalancesWETH = new uint256[](1);
        // lockedBalancesWETH[0] = 107264418100000000000;

        // uint256[] memory lockedBalancesUSDC = new uint256[](1);
        // lockedBalancesUSDC[0] = 1178792260000;

        string[] memory tickers = new string[](3);
        tickers[0] = "WBTC";
        tickers[1] = "WETH";
        tickers[2] = "USDC";

        uint256[] memory lockedBalances = new uint256[](3);
        lockedBalances[0] = 80359991;
        lockedBalances[1] = 107264418100000000000;
        lockedBalances[2] = 1178792260000;

        StreamVault btcVault = StreamVault(
            payable(0x6efa12b38038A6249B7aBdd5a047D211fB0aD48E)
        );
        StreamVault ethVault = StreamVault(
            payable(0x2a2f84e9AfE7b39146CDaF068b06b84EE23892c2)
        );
        StreamVault usdcVault = StreamVault(
            payable(0xf3b466F09ef476E311Ce275407Cfb09a8D8De3a7)
        );


        // console.logString("pre roll btc vault pricePerShare");
        // console.logUint(btcVault.pricePerShare());
        // MockERC20(wbtc).approve(address(keeper), 80359991);
        // keeper.rollRound(wbtcTicker, lockedBalancesWBTC);
        // console.logString("post roll btc vault pricePerShare");
        // console.logUint(btcVault.pricePerShare());
        // console.logString("pre roll  eth vault pricePerShare");
        // console.logUint(ethVault.pricePerShare());
        // MockERC20(weth).approve(address(keeper), 107264418100000000000);
        // keeper.rollRound(wethTicker, lockedBalancesWETH);
        // console.logString("post roll eth vault pricePerShare");
        // console.logUint(ethVault.pricePerShare());
        // console.logString("pre roll usdc vault pricePerShare");
        // console.logUint(usdcVault.pricePerShare());
        // MockERC20(usdc).approve(address(keeper), 1178792260000);
        // keeper.rollRound(usdcTicker, lockedBalancesUSDC);
        // console.logString("post roll usdc vault pricePerShare");
        // console.logUint(usdcVault.pricePerShare() );
        // console.logString("-------");
        // console.logString("Simulation successful");

        console.logString("pre roll btc vault pricePerShare");
        console.logUint(btcVault.pricePerShare());
        console.logString("pre roll eth vault pricePerShare");
        console.logUint(ethVault.pricePerShare());
        console.logString("pre roll usdc vault pricePerShare");
        console.logUint(usdcVault.pricePerShare());

        // MockERC20(wbtc).approve(address(keeper), 80359991);
        // MockERC20(weth).approve(address(keeper), 107264418100000000000);
        // MockERC20(usdc).approve(address(keeper), 1178792260000);
        keeper.rollRound(tickers, lockedBalances);

        console.logString("post roll btc vault pricePerShare");
        console.logUint(btcVault.pricePerShare());
        console.logString("post roll eth vault pricePerShare");
        console.logUint(ethVault.pricePerShare());
        console.logString("post roll usdc vault pricePerShare");
        console.logUint(usdcVault.pricePerShare());
        console.logString("-------");
        console.logString("Simulation successful");

        vm.stopPrank();
    }
}
