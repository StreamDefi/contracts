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

    enum Action {
        BORROW,
        REPAY,
        NONE
    }

    IDSProxy public proxy;
    IDSProxyFactory public proxyFactory;
    address public CDPManager;
    address public proxyActions;
    address public dai;
    address public weth;
    mapping(bytes32 => CDP) public cdps;
    /************************************************
     *  UNISWAP V3 STATE
     ***********************************************/
    ISwapRouter public immutable swapRouter;
    mapping(address tokenIn => mapping(address tokenOut => address pool))
        public uniV3Pools;
    uint public slippage = 3;

    constructor(
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
        uniV3Pools[weth][
            cdps[bytes32("WSTETH-B")].token
        ] = 0x109830a1AAaD605BbF02a9dFA7B0B92EC2FB7dAa;
    }

    /************************************************
     *  CDP ACTION WRAPPERS
     ***********************************************/
    function createProxy() public onlyOwner {
        IDSProxy _proxy = proxyFactory.build();
        require(
            address(_proxy) != address(0),
            "MakerLongLooper: Failed to create proxy"
        );
        proxy = _proxy;
    }

    function openVault(bytes32 _ilk) public onlyOwner {
        require(
            cdps[_ilk].collateralPool != address(0),
            "MakerLongLooper: Invalid ilk"
        );
        // open CDP vault
        bytes32 response = proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.open.selector,
                CDPManager,
                _ilk,
                proxy
            )
        );
        // store CDP id
        cdps[_ilk].cdpId = uint(response);
    }

    function depositCollateral(
        bytes32 _ilk,
        uint _depositAmount
    ) public onlyOwner {
        // load token into memory
        address token = cdps[_ilk].token;
        // check if contract has enough balance, else transfer from sender
        if (ERC20(token).balanceOf(address(this)) < _depositAmount) {
            ERC20(token).transferFrom(
                msg.sender,
                address(this),
                _depositAmount
            );
        }
        // approve proxy to spend token
        ERC20(token).approve(address(proxy), _depositAmount);

        // deposit collateral into CDP vault
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.lockGem.selector,
                CDPManager,
                cdps[_ilk].collateralPool,
                cdps[_ilk].cdpId,
                _depositAmount,
                true
            )
        );
    }

    function borrowDai(
        bytes32 _ilk,
        uint _daiAmount,
        bool _sendToOwner
    ) public onlyOwner {
        // borrow dai from CDP vault
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.draw.selector,
                CDPManager,
                cdps[_ilk].jug,
                cdps[_ilk].daiPool,
                cdps[_ilk].cdpId,
                _daiAmount
            )
        );

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
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.wipe.selector,
                CDPManager,
                cdps[_ilk].daiPool,
                cdps[_ilk].cdpId,
                _daiAmount
            )
        );
    }

    function withdrawCollateral(
        bytes32 _ilk,
        uint _freeAmount,
        bool _sendToOwner
    ) public onlyOwner {
        // free collateral from CDP vault
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.freeGem.selector,
                CDPManager,
                cdps[_ilk].collateralPool,
                cdps[_ilk].cdpId,
                _freeAmount
            )
        );

        // send collateral to owner
        if (_sendToOwner) {
            ERC20(cdps[_ilk].token).transfer(msg.sender, _freeAmount);
        }
    }

    function repayDebtAndFreeCollateral(
        bytes32 _ilk,
        uint _daiAmount,
        uint _freeAmount,
        bool _sendToOwner
    ) public onlyOwner {
        address token = cdps[_ilk].token;
        // check if contract has enough balance, else transfer from sender
        if (ERC20(dai).balanceOf(address(this)) < _daiAmount) {
            ERC20(dai).transferFrom(msg.sender, address(this), _daiAmount);
        }

        // approve proxy to spend token
        ERC20(dai).approve(address(proxy), _daiAmount);
        // repay dai debt and free collateral
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.wipeAndFreeGem.selector,
                CDPManager,
                cdps[_ilk].collateralPool,
                cdps[_ilk].daiPool,
                cdps[_ilk].cdpId,
                _freeAmount,
                _daiAmount
            )
        );

        // send collateral to owner
        if (_sendToOwner) {
            ERC20(token).transfer(msg.sender, _freeAmount);
        }
    }

    function depositCollateralAndBorrowDai(
        bytes32 _ilk,
        uint _depositAmount,
        uint _daiAmount,
        bool _sendToOwner
    ) public onlyOwner {
        address token = cdps[_ilk].token;
        // check if contract has enough balance, else transfer from sender
        if (ERC20(token).balanceOf(address(this)) < _depositAmount) {
            ERC20(token).transferFrom(
                msg.sender,
                address(this),
                _depositAmount
            );
        }
        // approve proxy to spend token
        ERC20(token).approve(address(proxy), _depositAmount);

        // deposit collateral into CDP vault and borrow dai
        proxy.execute(
            proxyActions,
            abi.encodeWithSelector(
                IDssProxyActions.lockGemAndDraw.selector,
                CDPManager,
                cdps[_ilk].jug,
                cdps[_ilk].collateralPool,
                cdps[_ilk].daiPool,
                cdps[_ilk].cdpId,
                _depositAmount,
                _daiAmount,
                true
            )
        );

        // send dai to owner
        if (_sendToOwner) {
            ERC20(dai).transfer(msg.sender, _daiAmount);
        }
    }

    /************************************************
     *  LEVERAGE LOOPER
     ************************************************/

    // function should withdraw enough collateral to meet _collateralToWithdraw
    // it should also meet the amount of leverage in _leverage
    // if this requires repaying debt, it should transfer dai from user to the contract to do so
    function executeWithdrawManagement(
        bytes32 _ilk,
        uint _leverage,
        uint _collateralToWithdraw
    ) public onlyOwner {
        // 1. check if we can withdraw _collateralToWithdraw amount with having a leverage that is met or lower than _leverage
        /*
       can meet _collateralToWithdraw amount and have a leverage that is either met oror lower than _leverage:
      */
        /*
        1. if we can meet _collateralToWithdraw amount and have a leverage that is either met or too low:
          - withdraw enough collateral to meet _collateralToWithdraw
      */
        /*
        2. if leverage is too low after this:
          - borrow more dai, swap, and deposit collateral to meet leverage amount

          if leverage is too high after this:
          - go to step 1 below
      */
        /*
        can not meet _collateralToWithdraw amount and have a leverage that is either met or lower than _leverage:
      */
        /*
        1. if we can meet _collateralToWithdraw amount and have a leverage that is either met or too low:
          - calculate how much debt needs to be repayed so we can withdraw _collateralToWithdraw amount and meet _leverage amount
          - transfer dai from owner, repay debt, withdraw collateral
      */
        // FINAL
        /*
         Now leverage amount is met, and we have _collateralToWithdraw amount of tokens:
          - send tokens to owner
      */
    }

    function executeDepositManagement(
        bytes32 _ilk,
        uint _leverage,
        uint _collateralToDeposit
    ) public onlyOwner {
        // 1. transfer _collateralToDeposit amount of tokens from owner to contract
        // 2. deposit _collateralToDeposit amount of tokens into vault
        // 3. check if current leverage after the deposit is higher than _leverage
        // IS HIGHER THAN _LEVERAGE
        /*
        1. calculate how much dai needs to be repayed so we can withdraw enough collateral to meet _leverage amount
          - transfer dai from owner, repay debt
      */
        // IS LOWER THAN _LEVERAGE
        /*
        1. if leverage is too low after this:
          - borrow more dai, swap, and deposit collateral to meet leverage amount
      */
    }

    function _getLevAfterAction(
        bytes32 _ilk,
        uint _daiPerCollateral,
        uint _amount,
        Action _action
    ) public view returns (uint) {
        (uint collateral, uint debt) = _getCollateralAndDebt(_ilk);
        uint collatVal = _getCollateralValue(
            collateral,
            _daiPerCollateral,
            ERC20(cdps[_ilk].token).decimals()
        );
        uint currLev = getCurrentLeverage(_ilk, _daiPerCollateral);
        if (_action == Action.REPAY) {
            return (collatVal) / (collatVal - (debt + _amount));
        } else {
            return (collatVal) / (collatVal - (debt - _amount));
        }
    }

    function getCorrectiveAction(
        bytes32 _ilk,
        uint _targetLev,
        uint _daiPerCollateral
    ) public view returns (uint amount, Action action) {
        (uint collateral, uint debt) = _getCollateralAndDebt(_ilk);
        uint collatVal = _getCollateralValue(
            collateral,
            _daiPerCollateral,
            ERC20(cdps[_ilk].token).decimals()
        );
        uint currLev = getCurrentLeverage(_ilk, _daiPerCollateral);

        if (currLev == _targetLev) return (0, Action.NONE);

        uint targetDebt = collatVal - (collatVal / _targetLev);

        if (_targetLev < currLev) {
            // need to repay debt
            uint debtToRepay = debt - targetDebt;
            return (debtToRepay, Action.REPAY);
        } else {
            // need to borrow dai
            uint daiToBorrow = targetDebt - debt;
            return (daiToBorrow, Action.BORROW);
        }
    }

    function _getCollateralValue(
        uint _collateral,
        uint _daiPerCollateral,
        uint _collatDec
    ) public view returns (uint) {
        return (_collateral * _daiPerCollateral) / 10 ** _collatDec;
    }

    function getCurrentLeverage(
        bytes32 _ilk,
        uint _daiPerCollateral
    ) public view returns (uint) {
        (uint collateral, uint debt) = _getCollateralAndDebt(_ilk);
        uint collatVal = (collateral * _daiPerCollateral) / 10 ** 18;
        return (collatVal / (collatVal - debt));
    }

    function _getUrn(bytes32 _ilk) public view returns (IVat.Urn memory) {
        address vat = ICDPManager(CDPManager).vat();
        return
            IVat(vat).urns(
                _ilk,
                ICDPManager(CDPManager).urns(cdps[_ilk].cdpId)
            );
    }

    function _getCollateralAndDebt(
        bytes32 _ilk
    ) public view returns (uint collateral, uint debt) {
        address vat = ICDPManager(CDPManager).vat();
        IVat.Urn memory urn = IVat(vat).urns(
            _ilk,
            ICDPManager(CDPManager).urns(cdps[_ilk].cdpId)
        );
        IVat.Ilk memory ilk = IVat(vat).ilks(_ilk);
        uint rate = ilk.rate;
        uint normalized_debt = urn.art;
        uint debt = (normalized_debt * rate) / 10 ** 27;
        uint collateral = urn.ink;
    }

    function loopLeverage(
        bytes32 _ilk,
        uint _borrowAmount,
        uint _daiPerCollateral
    ) public onlyOwner {
        borrowDai(_ilk, _borrowAmount, false);
        uint amountOutMin = ((_borrowAmount / _daiPerCollateral) * 10 ** 18) *
            ((100 - slippage) / 100);
        uint amountOut = swapExactTokens(
            _borrowAmount,
            cdps[_ilk].token,
            amountOutMin
        );
        depositCollateral(_ilk, amountOut);
    }

    // function getDaiToCollateralPrice(bytes32 _ilk) public view returns (uint) {
    //     address spotter = cdps[_ilk].spotter;
    //     (uint rate, bool ok) = ISpotter(spotter).peek(cdps[_ilk].ilk);
    //     require(ok, "MakerLongLooper: Failed to get price");
    //     return rate;
    // }

    /*
     * @notice - Assumes that the vault is already opened
     * @param _leverage - The amount of leverage to open the position with same amount of decimals as collateral token
     * @notice - The principleVal must be one such that withdrawing currentEquity - principle val still keeps the position healthy
     */
    // function openLeveragedPosition(
    //     bytes32 _ilk,
    //     uint _leverage,
    //     uint _daiToCollateralPrice,
    //     uint _principleVal
    // ) public onlyOwner {
    //     address vat = ICDPManager(CDPManager).vat();
    //     IVat.Urn memory urn = IVat(vat).urns(
    //         _ilk,
    //         ICDPManager(CDPManager).urns(cdps[_ilk].cdpId)
    //     );
    //     uint currCollateral = urn.ink;
    //     uint currDebt = urn.art;
    //     uint currCollateralVal = (currCollateral * _daiToCollateralPrice) /
    //         10 ** 18;
    //     uint currEquity = currCollateralVal - currDebt;
    //     // need to deposit or withdraw collateral from vault
    //     if (currEquity != _principleVal)
    //         handleEquity(
    //             _ilk,
    //             _daiToCollateralPrice,
    //             _principleVal,
    //             currEquity
    //         );

    //     currCollateral = urn.ink;
    //     currDebt = urn.art;
    //     currCollateralVal = (currCollateral * _daiToCollateralPrice) / 10 ** 18;
    //     currEquity = currCollateralVal - currDebt;

    //     if (currDebt == 0) {
    //         openFreshLeveragedPosition(
    //             _ilk,
    //             _leverage,
    //             _daiToCollateralPrice,
    //             _principleVal
    //         );
    //     } else {}
    // }

    // function handleEquity(
    //     bytes32 _ilk,
    //     uint _daiToCollateralPrice,
    //     uint _principleVal,
    //     uint _currEquity
    // ) internal {
    //     if (_principleVal > _currEquity) {
    //         // need to deposit collateral
    //         uint depositAmount = ((_principleVal - _currEquity) * 10 ** 18) /
    //             _daiToCollateralPrice;
    //         depositCollateral(_ilk, depositAmount);
    //     } else {
    //         // need to withdraw collateral

    //         // first check if we can do so without repaying debt
    //         uint withdrawAmount = ((_currEquity - _principleVal) * 10 ** 18) /
    //             _daiToCollateralPrice;
    //         withdrawCollateral(_ilk, withdrawAmount, true);
    //     }
    // }

    /*
    * @notice - Assumes that the vault is already opened
    * @notice - Assumes that the vault already has correct principle amount of equity

  */
    // function openFreshLeveragedPosition(
    //     bytes32 _ilk,
    //     uint _leverage,
    //     uint _daiToCollateralPrice,
    //     uint _depositAmount
    // ) internal {}

    /************************************************
     *  UNISWAP V3 SWAPPER
     ************************************************/
    function swapExactTokens(
        uint256 _amountIn,
        address _collateralToken,
        uint _amountOutMin
    ) public onlyOwner returns (uint256 amountOut) {
        if (ERC20(dai).balanceOf(address(this)) < _amountIn) {
            ERC20(dai).transferFrom(msg.sender, address(this), _amountIn);
        }

        TransferHelper.safeApprove(dai, address(swapRouter), _amountIn);

        IUniswapV3Pool daiToWETHPool = IUniswapV3Pool(uniV3Pools[dai][weth]);
        IUniswapV3Pool wethToCollateralPool = IUniswapV3Pool(
            uniV3Pools[weth][_collateralToken]
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(
                    dai,
                    daiToWETHPool.fee(),
                    weth,
                    wethToCollateralPool.fee(),
                    _collateralToken
                ),
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
