// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDSProxyFactory} from "./IDSProxyFactory.sol";
import {IDSProxy} from "./IDSProxy.sol";
import {IDssProxyActions} from "./IDssProxyActions.sol";
import {ISpotter} from "./ISpotter.sol";
import {ICDPManager} from "./ICDPManager.sol";
import {IVat} from "./IVat.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "forge-std/console.sol";

/**
 * @title - MakerLongLooper
 * @notice - This contract is responsible for opening leveraged margin long positions on maker
 */
contract MakerLongLooper is Ownable {


  /************************************************
    *  MAKER CDP STATE
  ***********************************************/

  struct CDP {
    bytes32 ilk;
    uint cdpId;
    address collateralPool;
    address token;
    address spotter;
    address jug;
    address daiPool;
  }

  IDSProxy public proxy;
  IDSProxyFactory public proxyFactory;
  address public CDPManager;
  address public proxyActions;
  address public dai;
  address public weth;
  mapping (bytes32 => CDP) public cdps;
  /************************************************
    *  UNISWAP V3 STATE
  ***********************************************/
  ISwapRouter public immutable swapRouter;
  mapping ( address tokenIn => mapping (address tokenOut => address pool)) public uniV3Pools;
  uint public slippage = 3;

  constructor (
    address _proxyFactory,
    address _CDPManager,
    address _DssProxyActions,
    address _dai,
    address _swapRouter,
    address _weth,
    CDP[] memory _cdps
  ) Ownable(msg.sender) {
    proxyFactory = IDSProxyFactory(_proxyFactory);
    CDPManager = _CDPManager;
    proxyActions = _DssProxyActions;
    dai = _dai;
    weth = _weth;
    swapRouter = ISwapRouter(_swapRouter);
 
    for (uint i = 0; i < _cdps.length; i++) {
      cdps[_cdps[i].ilk] = _cdps[i];
    }

    uniV3Pools[dai][weth] = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    uniV3Pools[weth][cdps[bytes32("WSTETH-B")].token] = 0x109830a1AAaD605BbF02a9dFA7B0B92EC2FB7dAa;

  }


  /************************************************
    *  CDP ACTION WRAPPERS
  ***********************************************/
  function createProxy() public onlyOwner {
    IDSProxy _proxy = proxyFactory.build();
    require(address(_proxy) != address(0), "MakerLongLooper: Failed to create proxy");
    proxy = _proxy;
  }

  function openVault(bytes32 _ilk) public onlyOwner {
    require(cdps[_ilk].collateralPool != address(0), "MakerLongLooper: Invalid ilk");
    // open CDP vault
    bytes32 response = proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.open.selector,
      CDPManager,
      _ilk,
      proxy
    ));
    // store CDP id
    cdps[_ilk].cdpId = uint(response);

  }


  function depositCollateral(bytes32 _ilk, uint _depositAmount) public onlyOwner {
    // load token into memory
    address token = cdps[_ilk].token;
    // check if contract has enough balance, else transfer from sender
    if (ERC20(token).balanceOf(address(this)) < _depositAmount) {
      ERC20(token).transferFrom(msg.sender, address(this), _depositAmount);
    }
    // approve proxy to spend token
    ERC20(token).approve(address(proxy), _depositAmount);

    // deposit collateral into CDP vault
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.lockGem.selector,
      CDPManager,
      cdps[_ilk].collateralPool,
      cdps[_ilk].cdpId, 
      _depositAmount,
      true
    ));
  }

  function borrowDai(bytes32 _ilk, uint _daiAmount, bool _sendToOwner) public onlyOwner {
    // borrow dai from CDP vault
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.draw.selector,
      CDPManager,
      cdps[_ilk].jug,
      cdps[_ilk].daiPool,
      cdps[_ilk].cdpId,
      _daiAmount
    ));

    // send dai to owner
    if (_sendToOwner) {
      ERC20(dai).transfer(msg.sender, _daiAmount);
    }
  }

  function repayDebt(bytes32 _ilk, uint _daiAmount) public onlyOwner {


    // check if contract has enough balance, else transfer from sender
    if (ERC20(dai).balanceOf(address(this)) < _daiAmount) {
      ERC20(dai).transferFrom(msg.sender, address(this), _daiAmount);
    }
    // repay dai debt
    ERC20(dai).approve(address(proxy), _daiAmount);
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.wipe.selector,
      CDPManager,
      cdps[_ilk].daiPool,
      cdps[_ilk].cdpId,
      _daiAmount
    ));
  }

  function withdrawCollateral(bytes32 _ilk, uint _freeAmount, bool _sendToOwner) public onlyOwner {
    // free collateral from CDP vault
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.freeGem.selector,
      CDPManager,
      cdps[_ilk].collateralPool,
      cdps[_ilk].cdpId,
      _freeAmount
    ));

    // send collateral to owner
    if (_sendToOwner) {
      ERC20(cdps[_ilk].token).transfer(msg.sender, _freeAmount);
    }
  }

  function repayDebtAndFreeCollateral(bytes32 _ilk, uint _daiAmount, uint _freeAmount, bool _sendToOwner) public onlyOwner {
    address token = cdps[_ilk].token;
    // check if contract has enough balance, else transfer from sender
    if (ERC20(dai).balanceOf(address(this)) < _daiAmount) {
      ERC20(dai).transferFrom(msg.sender, address(this), _daiAmount);
    }

    // approve proxy to spend token
    ERC20(dai).approve(address(proxy), _daiAmount);
    // repay dai debt and free collateral
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.wipeAndFreeGem.selector,
      CDPManager,
      cdps[_ilk].collateralPool,
      cdps[_ilk].daiPool,
      cdps[_ilk].cdpId,
      _freeAmount,
      _daiAmount
    ));

    // send collateral to owner
    if (_sendToOwner) {
      ERC20(token).transfer(msg.sender, _freeAmount);
    }
  }

  function depositCollateralAndBorrowDai(bytes32 _ilk, uint _depositAmount, uint _daiAmount, bool _sendToOwner) public onlyOwner {
    address token = cdps[_ilk].token;
    // check if contract has enough balance, else transfer from sender
    if (ERC20(token).balanceOf(address(this)) < _depositAmount) {
      ERC20(token).transferFrom(msg.sender, address(this), _depositAmount);
    }
    // approve proxy to spend token
    ERC20(token).approve(address(proxy), _depositAmount);

    // deposit collateral into CDP vault and borrow dai
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.lockGemAndDraw.selector,
      CDPManager,
      cdps[_ilk].jug,
      cdps[_ilk].collateralPool,
      cdps[_ilk].daiPool,
      cdps[_ilk].cdpId,
      _depositAmount,
      _daiAmount,
      true
    ));

    // send dai to owner
    if (_sendToOwner) {
      ERC20(dai).transfer(msg.sender, _daiAmount);
    }
  }

  /************************************************
    *  LEVERAGE LOOPER
  ************************************************/

  /*
    * @notice - Assumes that the vault is already opened
    * @param _leverage - The amount of leverage to open the position with same amount of decimals as collateral token
    * @notice - The principleVal must be one such that withdrawing currentEquity - principle val still keeps the position healthy

  */
  function openLeveragedPosition(bytes32 _ilk, uint _leverage, uint _daiToCollateralPrice, uint _principleVal) public onlyOwner {
    address vat = ICDPManager(CDPManager).vat();
    IVat.Urn memory urn = IVat(vat).urns(_ilk, ICDPManager(CDPManager).urns(cdps[_ilk].cdpId));
    uint currCollateral = urn.ink;
    uint currDebt = urn.art;
    uint currCollateralVal = currCollateral * _daiToCollateralPrice / 10 ** 18;
    uint currEquity = currCollateralVal - currDebt;
    // need to deposit or withdraw collateral from vault
    if (currEquity != _principleVal) handleEquity(_ilk, _daiToCollateralPrice, _principleVal, currEquity);

    currCollateral = urn.ink;
    currDebt = urn.art;
    currCollateralVal = currCollateral * _daiToCollateralPrice / 10 ** 18;
    currEquity = currCollateralVal - currDebt;

    if (currDebt == 0) {
      openFreshLeveragedPosition(_ilk, _leverage, _daiToCollateralPrice, _principleVal);
    } else {

    }
   

  }

  function handleEquity(bytes32 _ilk, uint _daiToCollateralPrice, uint _principleVal, uint _currEquity) internal {
    if (_principleVal > _currEquity) {
      // need to deposit collateral
      uint depositAmount = (_principleVal - _currEquity) * 10 ** 18 / _daiToCollateralPrice;
      depositCollateral(_ilk, depositAmount);
    } else {
      // need to withdraw collateral

      // first check if we can do so without repaying debt
      uint withdrawAmount = (_currEquity - _principleVal) * 10 ** 18 / _daiToCollateralPrice;
      withdrawCollateral(_ilk, withdrawAmount, true);
    }
  }

  /*
    * @notice - Assumes that the vault is already opened
    * @notice - Assumes that the vault already has correct principle amount of equity

  */
  function openFreshLeveragedPosition(bytes32 _ilk, uint _leverage, uint _daiToCollateralPrice, uint _depositAmount) internal {

  }




  /************************************************
    *  UNISWAP V3 SWAPPER
  ************************************************/
  function swapExactTokens(uint256 _amountIn, address _collateralToken, uint _amountOutMin) public onlyOwner returns(uint256 amountOut) {
    if (ERC20(dai).balanceOf(address(this)) < _amountIn) {
      ERC20(dai).transferFrom(msg.sender, address(this), _amountIn);
    }

    TransferHelper.safeApprove(dai, address(swapRouter), _amountIn);

    IUniswapV3Pool daiToWETHPool = IUniswapV3Pool(uniV3Pools[dai][weth]);
    IUniswapV3Pool wethToCollateralPool = IUniswapV3Pool(uniV3Pools[weth][_collateralToken]);

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: abi.encodePacked(dai, daiToWETHPool.fee(), weth, wethToCollateralPool.fee(), _collateralToken),
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _amountIn,
      amountOutMinimum: _amountOutMin
    });

    amountOut = swapRouter.exactInput(params);
  }

  /************************************************
    *  SETTERS
  ************************************************/

  function setCDP(bytes32 _ilk, CDP memory _cdp) public onlyOwner {
    cdps[_ilk] = _cdp;
  }
  function setProxyActions(address _proxyActions) public onlyOwner {
    proxyActions = _proxyActions;
  }

  function setDai(address _dai) public onlyOwner {
    dai = _dai;
  }

  function setProxy(address _proxy) public onlyOwner {
    proxy = IDSProxy(_proxy);
  }

  function setCDPManager(address _CDPManager) public onlyOwner {
    CDPManager = _CDPManager;
  }

  function setProxyFactory(address _proxyFactory) public onlyOwner {
    proxyFactory = IDSProxyFactory(_proxyFactory);
  }



  /************************************************
    *  EMERGENCY WITHDRAW
  *************************************************/
  function withdraw(address _token, uint _amount) public onlyOwner {
    if (_token == address(0)) {
      payable(owner()).transfer(_amount);
    } else {
      ERC20(_token).transfer(owner(), _amount);
    }
  }


}