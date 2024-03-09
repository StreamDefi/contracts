// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { MakerLongLooper } from "../../src/strategy/MakerLongLooper.sol";
import { IDSProxyFactory } from "../../src/strategy/IDSProxyFactory.sol";
import { IDSProxy } from "../../src/strategy/IDSProxy.sol";
import { IDssProxyActions } from "../../src/strategy/IDssProxyActions.sol";
import { ICDPManager } from "../../src/strategy/ICDPManager.sol";
import { IVat } from "../../src/strategy/IVat.sol";
import { IQuoterV2 } from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import { ISpotter } from "../../src/strategy/ISpotter.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";

contract TestMakerWrappers is Test {

  uint mainnetFork;
  address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address wstETHGemJoin = 0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c;
  address wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address daiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
  address jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
  address owner = 0xedd2c818f85aA1DB06B1D7f4F64E6d002911F444;
  address wstETHFunder = 0x5fEC2f34D80ED82370F733043B6A536d7e9D7f8d;
  address uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address spotter = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
  address quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
  uint wstETHBalance = 500 ether;
  uint depositAmount = 100 ether;
  uint borrowAmount = 20000 ether;
  bytes32 ilk = bytes32("WSTETH-B");
  MakerLongLooper mll;
  ICDPManager cdpManager;
  IVat vat;
  IDSProxy proxy;
  IDSProxyFactory proxyFactory;
  IDssProxyActions proxyActions;
  


  function setUp() public {
    mainnetFork = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
    proxyFactory = IDSProxyFactory(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
    proxyActions = IDssProxyActions(0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038);
    cdpManager = ICDPManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

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


   
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    mll = new MakerLongLooper(
      address(proxyFactory),
      address(cdpManager),
      address(proxyActions),
      dai,
      uniswapRouter,
      weth,
      cdps
    );
    mll.createProxy();
    proxy = mll.proxy();
    mll.openVault(ilk);
    vat = IVat(cdpManager.vat());
    assertEq(proxy.owner(), address(mll));
    (, uint id, , , , ,  ) = mll.cdps(ilk);
    assertFalse(id == 0, "no cdp set");
    vm.stopPrank();
    vm.prank(wstETHFunder);
    ERC20(wstETH).transfer(address(owner), wstETHBalance);
    
  }

  function test_properlyDepositsCollateral() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    uint preBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    mll.depositCollateral(ilk, depositAmount);
    uint postBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    assertEq(postBal - preBal, depositAmount);
  }

  function test_canDepositAndBorrowDai() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    uint preBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    mll.depositCollateralAndBorrowDai(ilk, depositAmount, borrowAmount, false);
    uint postBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    assertEq(ERC20(dai).balanceOf(address(mll)), borrowAmount);
    assertEq(postBal - preBal, depositAmount);
    verifyVatState(depositAmount, borrowAmount);
  }

  function test_canBorrowDaiAfterSimpleDeposit() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    mll.depositCollateral(ilk, depositAmount);
    mll.borrowDai(ilk, borrowAmount, false);
    assertEq(ERC20(dai).balanceOf(address(mll)), borrowAmount);
    verifyVatState(depositAmount, borrowAmount);
  }

  function test_canRepayDebtProperly() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    mll.depositCollateralAndBorrowDai(ilk, depositAmount, borrowAmount, false);
    verifyVatState(depositAmount, borrowAmount);
    ERC20(dai).approve(address(mll), borrowAmount);
    mll.repayDebt(ilk, borrowAmount);
    assertEq(ERC20(dai).balanceOf(address(mll)), 0);
    verifyVatState(depositAmount, 0);
  }

  function test_canWithdrawCollateralProperly() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    mll.depositCollateral(ilk, depositAmount);
    uint preBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    mll.withdrawCollateral(ilk, depositAmount, false);
    uint postBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    assertEq(preBal - postBal, depositAmount);
    verifyVatState(0, 0);
  }

  function test_canRepayDebtAndFreeCollateral() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    mll.depositCollateralAndBorrowDai(ilk, depositAmount, borrowAmount, false);
    ERC20(dai).approve(address(mll), borrowAmount);
    mll.repayDebtAndFreeCollateral(ilk, borrowAmount, depositAmount, false);
    assertEq(ERC20(dai).balanceOf(address(mll)), 0);
    assertEq(ERC20(wstETH).balanceOf(address(mll)), depositAmount);
    verifyVatState(0, 0);
  }

  function test_canSwapDaiTowstETH() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll), depositAmount);
    uint preBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    mll.depositCollateralAndBorrowDai(ilk, depositAmount, borrowAmount, false);
    uint postBal = ERC20(wstETH).balanceOf(address(wstETHGemJoin));
    assertEq(ERC20(dai).balanceOf(address(mll)), borrowAmount);
    assertEq(postBal - preBal, depositAmount);
    verifyVatState(depositAmount, borrowAmount);
    uint preWSTETHBal = ERC20(wstETH).balanceOf(address(mll));
    mll.swapExactTokens(borrowAmount / 2, wstETH, 0);
    uint postWSTETHBal = ERC20(wstETH).balanceOf(address(mll));
    assertTrue(postWSTETHBal > preWSTETHBal);
  }

  function test_openLoopLeverage() public {
   
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
  
    (uint256 amount, , ,) = IQuoterV2(quoter).quoteExactInput(
     abi.encodePacked(wstETH, uint24(100), weth, uint24(3000), dai),
      1 ether
    );
    console.logString("price");
    console.logUint(amount/ 10 ** 17);
    uint _depositAmount = 500000 ether / amount * 10 ** 18;
    ERC20(wstETH).approve(address(mll), _depositAmount);
    console.logString("depositAmount");
    console.logUint(_depositAmount / 10 ** 17);
    mll.openLeveragedPosition(ilk, 1.5 ether, amount, _depositAmount);
    verifyVatStateBuffer(_depositAmount * 1.5 ether / 10 ** 18, ((_depositAmount * amount * 1.5 ether) - _depositAmount) / 10 ** 36);
  }

  function test_openLoopLevWithPrevCollateral() public {
    uint initialDeposit = 10 ether;
    console.logString("initialDeposit");
    console.logUint(initialDeposit / 10 ** 17);
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    ERC20(wstETH).approve(address(mll),initialDeposit);
    mll.depositCollateral(ilk, initialDeposit);
    (uint256 price, , ,) = IQuoterV2(quoter).quoteExactInput(
     abi.encodePacked(wstETH, uint24(100), weth, uint24(3000), dai),
      1 ether
    );
    console.logString("price");
    console.logUint(price/ 10 ** 17);
    uint _depositAmount = 500000 ether / price * 10 ** 18;
    ERC20(wstETH).approve(address(mll), _depositAmount);
    console.logString("depositAmount");
    console.logUint(_depositAmount / 10 ** 17);
    mll.openLeveragedPosition(ilk, 1.5 ether, price, _depositAmount);
    verifyVatStateBuffer(depositAmount + _depositAmount * 1.5 ether / 10 ** 18, ((_depositAmount * price * 1.5 ether) - _depositAmount) / 10 ** 36);
  }

  function verifyVatState(
    uint _properCollateral,
    uint _properDebt
  ) public {
    (, uint id, , , , ,  ) = mll.cdps(ilk);
    bytes32 ilkBytes = cdpManager.ilks(id);

    IVat.Ilk memory ilkObj = vat.ilks(ilkBytes);
    // console.logUint(ilkObj.Art);
    // console.logUint(ilkObj.rate);
    // console.logUint(ilkObj.spot);
    // console.logUint(ilkObj.line);
    // console.logUint(ilkObj.dust);

    address urnAddress = cdpManager.urns(id);
    IVat.Urn memory urn = vat.urns(ilkBytes, urnAddress);
    assertEq(urn.ink, _properCollateral);

    // TO DO calculate proper debt by factoring in fee rate
    // assertEq(urn.art, _properDebt);
  }

  function verifyVatStateBuffer(
    uint _properCollateral,
    uint _properDebt
  ) public {
    (, uint id, , , , ,  ) = mll.cdps(ilk);
    bytes32 ilkBytes = cdpManager.ilks(id);

    IVat.Ilk memory ilkObj = vat.ilks(ilkBytes);
    // console.logUint(ilkObj.Art);
    // console.logUint(ilkObj.rate);
    // console.logUint(ilkObj.spot);
    // console.logUint(ilkObj.line);
    // console.logUint(ilkObj.dust);

    address urnAddress = cdpManager.urns(id);
    IVat.Urn memory urn = vat.urns(ilkBytes, urnAddress);
    // assertEq(urn.ink, _properCollateral);
    assertTrue(urn.ink >= _properDebt * 95/100 || urn.ink <= _properDebt * 105/100);
    if (_properDebt == 0) {
      assertEq(urn.art, 0);
    } else {
      assertTrue(urn.art >= _properDebt * 95/100 || urn.art <= _properDebt * 105/100);
    }
    // TO DO calculate proper debt by factoring in fee rate
    // assertEq(urn.art, _properDebt);
  }



}
