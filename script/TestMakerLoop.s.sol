// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import "forge-std/Script.sol";

import { MockERC20 } from "../mocks/MockERC20.sol";
import { MakerLongLooper } from "../src/strategy/MakerLongLooper.sol";
import "forge-std/console.sol";

interface DSProxy {
  function execute(address _target, bytes memory _data)
        external
        payable
        returns (bytes32 response);

}
contract TestMakerLoop is Script {
  function run() public {
    // address owner = 0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444;
    // address funder = 0x5313b39bf226ced2332C81eB97BB28c6fD50d1a3;
    // DssProxyActions makerProxy = DssProxyActions(0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038);
    // MockERC20 wstETH = MockERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    // MockERC20 dai = MockERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // DSProxy proxy = DSProxy(0x44E36d740aA2066669644AAFFA90f69aA74E3aa9);
    // vm.prank(funder);
    // wstETH.transfer(address(owner), 100 ether);
    
    // vm.startPrank(owner);
    // MakerLongLooper makerLongLooper = new MakerLongLooper();
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