// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface GnosisSafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

contract RestrictedSendModule {
    enum Operation {
        Call,
        DelegateCall
    }

    struct MorphoMarket {

    }

    address public safe;
    address public constant TARGET_ADDRESS =
        0x9867ceb9be4F71BDaf9060447659aBdBD0B74087;
    mapping(uint id => MorphoMarket) public morphoMarkets;
    address public morphoBlue;
    string public constant MORPHO_SUPPLY = "supply((address,address,address,address,uint256), uint256, uint256, address, bytes)";
    string public constant MORPHO_WITHDRAW = "withdraw((address,address,address,address,uint256), uint256, uint256, address, address)";
    string public constant MORPHO_BORROW = "borrow((address,address,address,address,uint256), uint256, uint256, address, address)";
    string public constant MORPHO_SUPPLY_COLLATERAL = "supplyCollateral((address,address,address,address,uint256), uint256, address, bytes)";
    string public constant MORPHO_WTHDRAW_COLLATERL = "withdrawCollateral((address,address,address,address,uint256), uint256, address, address)";
    string public constant MORPHO_REPAY = "repay((address,address,address,address,uint256), uint256, uint256, address, bytes)";
    string public constant APPROVAL = "approve(address,uint256)";


    constructor(
        address _safe,
        address _multisig,
        address _morphoBlue
        MorphoMarket[] memory _morphoMarkets
    ) Ownable(_multisig) {

      morphoBlue = _morphoBlue
      safe = _safe;
      for (uint i = 0; i <_morphoMarkets.length;) {
        morphoMarkets[i] = _morphoMarkets[i];
        unchecked {
          ++i;
        }
      }
      
    }

    /************************************************
     *  MORPHO
     ***********************************************/
    function morphoSupply(uint256 _amount, uint256 _market) external onlyOwner {
      require(_amount > 0, "Invalid amount");
      MorphoMarkets memory market = morphoMarkets[_market];

      approveToken(market.loanToken, morphoBlue, _amount);
      bytes memory txData = abi.encodeWithSignature(MORPHO_SUPPLY, market, _amount, 0, msg.sender, "0x");

      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );

      require(success, "Supply failed");
    }

    function morphoWithdraw(uint256 _shares, uint256 _market) external onlyOwner {
      require (_shares > 0 "Invalid shares");
      MorphoMarkets memory market = morphoMarkets[_market];
      bytes memory txData = abi.encodeWithSignature(MORPHO_WITHDRAW, market, 0, _shares, msg.sender, msg.sender);
      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );
      require(success, "Withdraw failed")
    }

    function morphoBorrow(uint256 _amount, uint256 _market) external onlyOwner {
      require(_amount > 0, "Invalid amount");
      MorphoMarkets memory market = morphoMarkets[_market];
      bytes memory txData = abi.encodeWithSignature(MORPHO_BORROW, market, _amount, 0, msg.sender, msg.sender);
      // check safety of position here before initiating
      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );
      require(success, "Borrowing failed")
    }

    function morphoSupplyCollateral(uint256 _amount, uint256 _market) external onlyOwner {
      require(_amount > 0, "Invalid amount");
      MorphoMarkets memory market = morphoMarkets[_market];
      approveToken(market.collateralToken, morphoBlue, _amount);
      bytes memory txData = abi.encodeWithSignature(MORPHO_SUPPLY_COLLATERAL, market, _amount, msg.sender, "0x");

      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );

      require(success, "Supplying collateral failed");
    }

    function morphoWithdrawCollateral(uint256 _amount, uint256 _market) external onlyOwner {
      require(_amount > 0, "Invalid amount");
      MorphoMarkets memory market = morphoMarkets[_market];
      bytes memory txData = abi.encodeWithSignature(MORPHO_WITHDRAW_COLLATERAL, market, _amount, msg.sender, msg.sender);

      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );

      require(success, "Withdrawing collateral failed");
    }

    function morphoRepay(uint256 _shares, uint256 _market) external onlyOwner {
      require(_amount > 0, "Invalid amount");
      MorphoMarkets memory market = morphoMarkets[_market];
      // calculate  shares => token conversion 
      approveToken(market.loanToken, morphoBlue, _amount);
      bytes memory txData = abi.encodeWithSignature(MORPHO_REPAY, market, 0, _shares, msg.sender, "0x");

      bool success = GnosisSafe(safe).execTransactionFromModule(
          morphoBlue,
          0,
          txData,
          Enum.Operation.Call
      );

      require(success, "Repay failed");
    }


    /************************************************
     *  GENERAL
     ***********************************************/
    function approveToken(address _token, address _operator, uint _amount) internal {
      bytes memory txData = abi.encodeWithSignature(APPROVAL, _operator, _amount);
      bool success = GnosisSafe(safe).execTransactionFromModule(
        _token,
        0,
        ,
        Enum.Operation.Call
      );
      require(success, "Transfer failed");
    }

    
    receive() external payable {}
}
