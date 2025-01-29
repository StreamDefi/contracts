// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IStableWrapper} from "./interfaces/IStableWrapper.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

contract StableWrapper is OFT, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public asset;
    uint32 public currentEpoch;
    bool public allowIndependence;

    address public keeper;

    // Withdrawal receipt mapping
    struct WithdrawalReceipt {
        uint224 amount;
        uint32 epoch;
    }

    mapping(address => WithdrawalReceipt) public withdrawalReceipts;

    // Events
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event DepositToVault(address indexed user, uint256 amount);
    event WithdrawalInitiated(address indexed user, uint224 amount, uint32 epoch);
    event Withdrawn(address indexed user, uint256 amount);
    event EpochAdvanced(uint32 newEpoch);
    event AssetTransferred(address indexed to, uint256 amount);
    event PermissionedMint(address indexed to, uint256 amount);
    event PermissionedBurn(address indexed from, uint256 amount);
    event AllowIndependenceSet(bool allowIndependence);
    event KeeperSet(address keeper);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _keeper,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        require(_keeper != address(0), "Invalid keeper address");
        asset = _asset;
        currentEpoch = 1;
        allowIndependence = false;
        keeper = _keeper;
    }

    /**
     * @notice Deposits assets and mints equivalent tokens to the vault
     * @param amount Amount of assets to deposit
     */
    function depositToVault(address from, uint256 amount) public nonReentrant onlyOwner {
        if (amount == 0) revert("2");

        // Mint equivalent tokens to the vault
        _mint(owner(), amount);

        emit DepositToVault(from, amount);

        // Transfer assets from specified address
        IERC20(asset).safeTransferFrom(from, address(this), amount);
    }

    /**
     * @notice Deposits assets from a specified address and mints equivalent tokens
     * @param to Address to transfer assets to
     * @param amount Amount of assets to deposit
     */
    function deposit(address to, uint256 amount) public nonReentrant {
        if (!allowIndependence) revert("1");
        if (amount == 0) revert("2");

        // Mint equivalent tokens to the specified address
        _mint(to, amount);

        // Transfer assets from specified address
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, to, amount);
    }

    /**
     * @notice Burns tokens and creates withdrawal receipt
     * @param amount Amount of tokens to burn for withdrawal
     */
    function initiateWithdrawal(uint224 amount) public nonReentrant {
        if (!allowIndependence) revert("1");
        if (amount == 0) revert("2");
        if (balanceOf(msg.sender) < amount) revert("10");

        // Burn tokens
        _burn(msg.sender, amount);

        uint224 currentAmount = withdrawalReceipts[msg.sender].amount;

        // Create withdrawal receipt
        withdrawalReceipts[msg.sender] = WithdrawalReceipt({amount: currentAmount + amount, epoch: currentEpoch});

        emit WithdrawalInitiated(msg.sender, amount, currentEpoch);
    }

    /**
     * @notice Burns tokens and creates withdrawal receipt for a specified address
     * @param from Address to burn tokens from and create withdrawal receipt for
     * @param amount Amount of tokens to burn for withdrawal
     */
    function initiateWithdrawalFromVault(address from, uint224 amount) public nonReentrant onlyOwner {
        if (amount == 0) revert("2");

        // Burn tokens from the specified address
        _burn(address(this), amount);

        uint224 currentAmount = withdrawalReceipts[from].amount;

        // Create withdrawal receipt for the specified address
        withdrawalReceipts[from] = WithdrawalReceipt({amount: currentAmount + amount, epoch: currentEpoch});

        emit WithdrawalInitiated(from, amount, currentEpoch);
    }

    /**
     * @notice Complete withdrawal if epoch has passed
     * @param to Address to transfer assets to
     */
    function completeWithdrawal(address to) public nonReentrant {
        WithdrawalReceipt memory receipt = withdrawalReceipts[msg.sender];

        if (receipt.amount == 0) revert("11");
        if (receipt.epoch >= currentEpoch) revert("12");

        // Cast uint224 to uint256 explicitly for the transfer
        uint256 amountToTransfer = uint256(receipt.amount);

        // Clear receipt
        delete withdrawalReceipts[msg.sender];

        // Transfer assets back to user
        IERC20(asset).safeTransfer(to, amountToTransfer);

        emit Withdrawn(to, amountToTransfer);
    }

    /**
     * @notice Advances to next epoch
     */
    function advanceEpoch() public {
        _onlyAddress(keeper);
        currentEpoch += 1;
        emit EpochAdvanced(currentEpoch);
    }

    function setKeeper(address _keeper) public {
        _onlyAddress(keeper);
        require(_keeper != address(0), "Invalid keeper address");
        keeper = _keeper;
        emit KeeperSet(_keeper);
    }

    function _onlyAddress(address privilegedAddy) internal view {
        if (msg.sender != privilegedAddy) revert("13");
    }

    /**
     * @notice Allows owner to set allowIndependence
     * @param _allowIndependence New allowIndependence value
     */
    function setAllowIndependence(bool _allowIndependence) public {
        _onlyAddress(keeper);
        allowIndependence = _allowIndependence;
        emit AllowIndependenceSet(_allowIndependence);
    }

    /**
     * @notice Allows keeper to set the asset address
     * @param _asset New asset address
     */
    function setAsset(address _asset) public {
        _onlyAddress(keeper);
        require(_asset != address(0), "Invalid asset address");
        asset = _asset;
    }

    /**
     * @notice Allows owner to transfer assets to specified address
     * @param to Address to transfer assets to
     * @param amount Amount of assets to transfer
     * @param _token Address of the token to transfer
     */
    function transferAsset(address to, uint256 amount, address _token) public {
        _onlyAddress(keeper);
        require(amount > 0, "Amount must be greater than 0");

        emit AssetTransferred(to, amount);

        IERC20(_token).safeTransfer(to, amount);
    }

    /**
     * @notice Allows owner to mint tokens to a specified address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function permissionedMint(address to, uint256 amount) public onlyOwner {
        if (amount == 0) revert("2");
        _mint(to, amount);
        emit PermissionedMint(to, amount);
    }

    /**
     * @notice Allows owner to burn tokens from a specified address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function permissionedBurn(address from, uint256 amount) public onlyOwner {
        if (amount == 0) revert("2");
        _burn(from, amount);
        emit PermissionedBurn(from, amount);
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return ERC20(asset).decimals();
    }

    /**
     * @notice Returns the shared token decimals for OFT
     */
    function sharedDecimals() public view virtual override returns (uint8) {
        return decimals();
    }
}
