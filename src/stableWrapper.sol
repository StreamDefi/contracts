// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IStableWrapper} from "./interfaces/IStableWrapper.sol";
contract StableWrapper is IStableWrapper, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable asset;
    uint32 public currentEpoch;
    bool public allowIndependence;

    // Withdrawal receipt mapping
    struct WithdrawalReceipt {
        uint224 amount;
        uint32 epoch;
    }
    mapping(address => WithdrawalReceipt) public withdrawalReceipts;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event WithdrawalInitiated(
        address indexed user,
        uint224 amount,
        uint32 epoch
    );
    event Withdrawn(address indexed user, uint256 amount);
    event EpochAdvanced(uint32 newEpoch);
    event AssetTransferred(address indexed to, uint256 amount);
    event PermissionedMint(address indexed to, uint256 amount);
    event PermissionedBurn(address indexed from, uint256 amount);
    event AllowIndependenceSet(bool allowIndependence);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        asset = _asset;
        currentEpoch = 1;
        allowIndependence = false;
    }

    /**
     * @notice Deposits assets and mints equivalent tokens
     * @param amount Amount of assets to deposit
     */
    function deposit(uint256 amount) public nonReentrant {
        if (allowIndependence) {
            require(msg.sender == owner(), "Only owner can deposit");
        }

        require(amount > 0, "Amount must be greater than 0");

        // Transfer assets from user
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Mint equivalent tokens to user
        _mint(msg.sender, amount);

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Burns tokens and creates withdrawal receipt
     * @param amount Amount of tokens to burn for withdrawal
     */
    function initiateWithdrawal(uint224 amount) public nonReentrant {
        if (allowIndependence) {
            require(
                msg.sender == owner(),
                "Only owner can initiate withdrawal"
            );
        }

        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Burn tokens
        _burn(msg.sender, amount);

        uint224 currentAmount = withdrawalReceipts[msg.sender].amount;

        // Create withdrawal receipt
        withdrawalReceipts[msg.sender] = WithdrawalReceipt({
            amount: currentAmount + amount,
            epoch: currentEpoch
        });

        emit WithdrawalInitiated(msg.sender, amount, currentEpoch);
    }

    /**
     * @notice Complete withdrawal if epoch has passed
     */
    function completeWithdrawal() public nonReentrant {
        if (allowIndependence) {
            require(
                msg.sender == owner(),
                "Only owner can complete withdrawal"
            );
        }

        WithdrawalReceipt memory receipt = withdrawalReceipts[msg.sender];

        require(receipt.amount > 0, "No withdrawal pending");
        require(receipt.epoch < currentEpoch, "Epoch not yet passed");

        // Cast uint224 to uint256 explicitly for the transfer
        uint256 amountToTransfer = uint256(receipt.amount);

        // Clear receipt
        delete withdrawalReceipts[msg.sender];

        // Transfer assets back to user
        IERC20(asset).safeTransfer(msg.sender, amountToTransfer);

        emit Withdrawn(msg.sender, amountToTransfer);
    }

    /**
     * @notice Advances to next epoch
     */
    function advanceEpoch() public onlyOwner {
        currentEpoch += 1;
        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @notice Allows owner to set allowIndependence
     * @param _allowIndependence New allowIndependence value
     */
    function setAllowIndependence(bool _allowIndependence) public onlyOwner {
        allowIndependence = _allowIndependence;
        emit AllowIndependenceSet(_allowIndependence);
    }

    /**
     * @notice Allows owner to transfer assets to specified address
     * @param to Address to transfer assets to
     * @param amount Amount of assets to transfer
     */
    function transferAsset(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20(asset).safeTransfer(to, amount);
        emit AssetTransferred(to, amount);
    }

    /**
     * @notice Allows owner to mint tokens to a specified address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function permissionedMint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");

        _mint(to, amount);
        emit PermissionedMint(to, amount);
    }

    /**
     * @notice Allows owner to burn tokens from a specified address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function permissionedBurn(address from, uint256 amount) public onlyOwner {
        require(from != address(0), "Cannot burn from zero address");
        require(amount > 0, "Amount must be greater than 0");

        _burn(from, amount);
        emit PermissionedBurn(from, amount);
    }
}
