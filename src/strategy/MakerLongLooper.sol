// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDSProxyFactory} from "./IDSProxyFactory.sol";
import { IDSProxy} from "./IDSProxy.sol";
import {IDssProxyActions} from "./IDssProxyActions.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import "forge-std/console.sol";

/**
 * @title - MakerLongLooper
 * @notice - This contract is responsible for opening leveraged margin long positions on maker
 */
contract MakerLongLooper is Ownable {


  /************************************************
    *  MAKER CDP STATE
  ***********************************************/

  IDSProxy public proxy;
  IDSProxyFactory public proxyFactory;
  address public CDPManager;
  address public proxyActions;
  address public dai;
  mapping (bytes32 => address) public collateralPools;
  mapping (bytes32 => uint) public cdps;
  mapping (bytes32 => address) public tokens;
  mapping (bytes32 => address) public jugs;
  mapping (bytes32 => address) public daiPools;


  /************************************************
    *  UNISWAP V3 STATE
  ***********************************************/
  ISwapRouter public immutable swapRouter;

  constructor (
    address _proxyFactory,
    address _CDPManager,
    address _DssProxyActions,
    address _dai,
    address _swapRouter,
    bytes32[] memory _ilks,
    address[] memory _collateralPools,
    address[] memory _tokens,
    address[] memory _jugs,
    address[] memory _daiPools

  ) Ownable(msg.sender) {
    proxyFactory = IDSProxyFactory(_proxyFactory);
    CDPManager = _CDPManager;
    proxyActions = _DssProxyActions;
    dai = _dai;
    swapRouter = ISwapRouter(_swapRouter);
    require (
    _ilks.length == _collateralPools.length && 
    _ilks.length == _tokens.length &&
    _jugs.length == _tokens.length &&
    _ilks.length == _daiPools.length, 
    "MakerLongLooper: Invalid input"
    );
    for (uint i = 0; i < _collateralPools.length;) {
      collateralPools[_ilks[i]] = _collateralPools[i];
      tokens[_ilks[i]] = _tokens[i];
      jugs[_ilks[i]] = _jugs[i];
      daiPools[_ilks[i]] = _daiPools[i];
      unchecked {++i;}
    }
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
    require(collateralPools[_ilk] != address(0), "MakerLongLooper: Invalid ilk");
    // open CDP vault
    bytes32 response = proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.open.selector,
      CDPManager,
      _ilk,
      proxy
    ));
    // store CDP id
    cdps[_ilk] = uint(response);

  }


  function depositCollateral(bytes32 _ilk, uint _depositAmount) public onlyOwner {
    // load token into memory
    address token = tokens[_ilk];
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
      collateralPools[_ilk],
      cdps[_ilk], 
      _depositAmount,
      true
    ));
  }

  function borrowDai(bytes32 _ilk, uint _daiAmount, bool _sendToOwner) public onlyOwner {
    // borrow dai from CDP vault
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.draw.selector,
      CDPManager,
      jugs[_ilk],
      daiPools[_ilk],
      cdps[_ilk],
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
      daiPools[_ilk],
      cdps[_ilk],
      _daiAmount
    ));
  }

  function withdrawCollateral(bytes32 _ilk, uint _freeAmount, bool _sendToOwner) public onlyOwner {
    // free collateral from CDP vault
    proxy.execute(proxyActions, abi.encodeWithSelector(
      IDssProxyActions.freeGem.selector,
      CDPManager,
      collateralPools[_ilk],
      cdps[_ilk],
      _freeAmount
    ));

    // send collateral to owner
    if (_sendToOwner) {
      ERC20(tokens[_ilk]).transfer(msg.sender, _freeAmount);
    }
  }

  function repayDebtAndFreeCollateral(bytes32 _ilk, uint _daiAmount, uint _freeAmount, bool _sendToOwner) public onlyOwner {
    address token = tokens[_ilk];
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
      collateralPools[_ilk],
      daiPools[_ilk],
      cdps[_ilk],
      _freeAmount,
      _daiAmount
    ));

    // send collateral to owner
    if (_sendToOwner) {
      ERC20(token).transfer(msg.sender, _freeAmount);
    }
  }

  function depositCollateralAndBorrowDai(bytes32 _ilk, uint _depositAmount, uint _daiAmount, bool _sendToOwner) public onlyOwner {
    address token = tokens[_ilk];
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
      jugs[_ilk],
      collateralPools[_ilk],
      daiPools[_ilk],
      cdps[_ilk],
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
    *  SETTERS
  ************************************************/
  function setProxyActions(address _proxyActions) public onlyOwner {
    proxyActions = _proxyActions;
  }

  function setDai(address _dai) public onlyOwner {
    dai = _dai;
  }

  function setToken(bytes32 _ilk, address _token) public onlyOwner {
    tokens[_ilk] = _token;
  }

  function setJug(bytes32 _ilk, address _jug) public onlyOwner {
    jugs[_ilk] = _jug;
  }

  function setDaiPool(bytes32 _ilk, address _daiPool) public onlyOwner {
    daiPools[_ilk] = _daiPool;
  }

  function setProxy(address _proxy) public onlyOwner {
    proxy = IDSProxy(_proxy);
  }

  function setCDP(bytes32 _ilk, uint _cdp) public onlyOwner {
    cdps[_ilk] = _cdp;
  }

  function setCollateralPool(bytes32 _ilk, address _collateralPool) public onlyOwner {
    collateralPools[_ilk] = _collateralPool;
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