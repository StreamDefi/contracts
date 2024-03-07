// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import "forge-std/Script.sol";

import { MockERC20 } from "../mocks/MockERC20.sol";
import { MakerLongLooper } from "../src/strategy/MakerLongLooper.sol";
import { IDSProxyFactory } from "../src/strategy/IDSProxyFactory.sol";
import { IDSProxy } from "../src/strategy/IDSProxy.sol";
import { ISpotter } from "../src/strategy/ISpotter.sol";
import { IDssProxyActions } from "../src/strategy/IDssProxyActions.sol";
import "forge-std/console.sol";

interface DSProxy {
  function execute(address _target, bytes memory _data)
        external
        payable
        returns (bytes32 response);

}
contract TestMakerLoop is Script {

  address CDPManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
  address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address wstETHGemJoin = 0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c;
  address wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address daiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
  address jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
  address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address owner = 0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444;
  address uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address spotter = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
  IDSProxy proxy;
  IDSProxyFactory proxyFactory;
  IDssProxyActions proxyActions;
  function run() public {
  
    // address funder = 0x5313b39bf226ced2332C81eB97BB28c6fD50d1a3;
    // DssProxyActions makerProxy = DssProxyActions(0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038);
    // MockERC20 wstETH = MockERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    // MockERC20 dai = MockERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // DSProxy proxy = DSProxy(0x44E36d740aA2066669644AAFFA90f69aA74E3aa9);
    // vm.prank(funder);
    // wstETH.transfer(address(owner), 100 ether);
    
    vm.startPrank(owner);
    proxyFactory = IDSProxyFactory(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
    proxyActions = IDssProxyActions(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
    bytes32[] memory ilks = new bytes32[](1);
     MakerLongLooper.CDP[] memory cdps = new MakerLongLooper.CDP[](1);
    cdps[0] = MakerLongLooper.CDP({
      ilk: bytes32("WSTETH-B"),
      cdpId: 0,
      collateralPool: wstETHGemJoin,
      token: wstETH,
      spotter: spotter,
      jug: jug,
      daiPool: daiJoin
    });



    MakerLongLooper mll = new MakerLongLooper(
      address(proxyFactory),
      CDPManager,
      address(proxyActions),
      dai,
      uniswapRouter,
      weth,
     cdps
    );
    mll.createProxy();
    proxy = mll.proxy();
    console.logAddress(proxy.owner());
    console.logAddress(address(mll));

    // wstETH.approve(address(makerProxy), 50 ether);
    // makerProxy.lockGem(
    //   address(0x5ef30b9986345249bc32d8928B7ee64DE9435E39),
    //   address(0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c),
    //   31498, 
    //   50 ether,
    //   true
    // );
    // console.logUint(dai.balanceOf(address(owner)));
    // // makerLongLooper.delegate();
   

    // // proxy.execute(address(makerProxy), abi.encodeWithSelector(makerProxy.draw.selector,
    // //    address(0x5ef30b9986345249bc32d8928B7ee64DE9435E39),
    // //    address(0x19c0976f590D67707E62397C87829d896Dc0f1F1),
    // //    address(0x9759A6Ac90977b93B58547b4A71c78317f391A28),
    // //    31498,
    // //    1000 ether
    // // ));
    //  console.logUint(dai.balanceOf(address(owner)));
    // // makerProxy.draw(
    // //    address(0x5ef30b9986345249bc32d8928B7ee64DE9435E39),
    // //    address(0x19c0976f590D67707E62397C87829d896Dc0f1F1),
    // //    address(0x9759A6Ac90977b93B58547b4A71c78317f391A28),
    // //    31498,
    // //    1000 ether
    // // );
  }
}