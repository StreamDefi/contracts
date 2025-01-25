// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable asset;

    struct WrapperParams {
        uint32 currentEpoch;
        uint224 withdrawlDiscountPpm;
    }
    WrapperParams public wrapperParams;

    // 1 million in parts per million (PPM)
    uint224 public constant MILLION_PPM = 1_000_000;
    
    // Withdrawal receipt mapping
    struct WithdrawalReceipt {
        uint224 amount;
        uint32 epoch;
    }
    mapping(address => WithdrawalReceipt) public withdrawalReceipts;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event WithdrawalInitiated(address indexed user, uint256 amount, uint256 epoch);
    event Withdrawn(address indexed user, uint256 amount);
    event EpochAdvanced(uint256 newEpoch);
    event AssetTransferred(address indexed to, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        asset = _asset;
        wrapperParams = WrapperParams({
            currentEpoch: 1,
            withdrawlDiscountPpm: 1_000_000
        });
    }

    /**
     * @notice Deposits assets and mints equivalent tokens
     * @param amount Amount of assets to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer assets from user
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        
        // Mint equivalent tokens to user
        _mint(msg.sender, amount);
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Burns tokens and creates withdrawal receipt
     * @param amount Amount of tokens to burn for withdrawal
     */
    function initiateWithdrawal(uint224 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Burn tokens
        _burn(msg.sender, amount);

        uint224 currentAmount = withdrawalReceipts[msg.sender].amount;

        // Create withdrawal receipt
        withdrawalReceipts[msg.sender] = WithdrawalReceipt({
            amount: currentAmount + amount,
            epoch: wrapperParams.currentEpoch
        });

        emit WithdrawalInitiated(msg.sender, amount, wrapperParams.currentEpoch);
    }

    /**
     * @notice Complete withdrawal if epoch has passed
     */
    function completeWithdrawal() external nonReentrant {
        WithdrawalReceipt memory receipt = withdrawalReceipts[msg.sender];
        WrapperParams memory params = wrapperParams;



        require(receipt.amount > 0, "No withdrawal pending");
        require(receipt.epoch < params.currentEpoch, "Epoch not yet passed");

        uint224 amount = receipt.amount;
        uint224 amountAfterDiscount = amount * params.withdrawlDiscountPpm / MILLION_PPM;
        // Clear receipt
        delete withdrawalReceipts[msg.sender];

        // Transfer assets back to user
        IERC20(asset).safeTransfer(msg.sender, amountAfterDiscount);

        emit Withdrawn(msg.sender, amountAfterDiscount);
    }

    /**
     * @notice Advances to next epoch
     */
    function advanceEpoch() external onlyOwner {
        WrapperParams memory params = wrapperParams;
        params.currentEpoch += 1;
        wrapperParams = params;
        emit EpochAdvanced(params.currentEpoch);
    }

    /**
     * @notice Sets the withdrawal discount ppm
     * @param _withdrawlDiscountPpm New withdrawal discount ppm
     */
    function setWithdrawlDiscountPpm(uint224 _withdrawlDiscountPpm) external onlyOwner {
        require(_withdrawlDiscountPpm <= MILLION_PPM, "Invalid withdrawl discount ppm");
        wrapperParams.withdrawlDiscountPpm = _withdrawlDiscountPpm;
    }

    /**
     * @notice Allows owner to transfer assets to specified address
     * @param to Address to transfer assets to
     * @param amount Amount of assets to transfer
     */
    function transferAsset(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(asset).safeTransfer(to, amount);
        emit AssetTransferred(to, amount);
    }
}