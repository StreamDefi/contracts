// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ShareMath} from "./lib/ShareMath.sol";
import {Vault} from "./lib/Vault.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MerkleProofLib} from "lib/solady/src/utils/MerkleProofLib.sol";

/**
 * @title StreamVault
 * @notice A vault that allows users to stake and withdraw from an off-chain managed Stream strategy
 * @notice Users receive shares for their stakes, which can be redeemed for assets
 * @notice The vault is managed by a keeper, who is responsible for rolling to the next round
 * @notice The rounds will be rolled over on a weekly basis
 */

contract StreamVault is ReentrancyGuard, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using ShareMath for Vault.StakeReceipt;
    using MerkleProofLib for bytes32[];

    /************************************************
     *  STATE
     ***********************************************/
    /// @notice Stores the user's pending stake for the round
    mapping(address => Vault.StakeReceipt) public stakeReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their StakeReceipt.stakeAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice The total amount of 'asset' that is queued for withdrawal
    uint256 public totalQueuedWithdrawAmount;

    /// @notice The amount of 'asset' that is queued for withdrawal in the current round
    uint256 public currentQueuedWithdrawAmount;

    /// @notice role in charge of weekly vault operations such as rollToNextRound
    // no access to critical vault changes
    address public keeper;

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice private or public
    bool public isPublic;

    /// @notice merkle root for private whitelist
    bytes32 public merkleRoot;

    /************************************************
     *  EVENTS
     ***********************************************/
    event Stake(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );
    event Withdraw(address indexed account, uint256 amount);

    event Redeem(address indexed account, uint256 share, uint256 round);

    event CapSet(uint256 oldCap, uint256 newCap);

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    /************************************************
     *  MODIFIERS
     ***********************************************/

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Native token contract
     * @param _keeper is the role that will handle funds and advancing rounds
     * @param _tokenName is the token name of the share ERC-20
     * @param _tokenSymbol is the token symbol of the share ERC-20
     * @param _vaultParams is the `VaultParams` struct with general vault data
     */
    constructor(
        address _weth,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) ReentrancyGuard() Ownable(msg.sender) ERC20(_tokenName, _tokenSymbol) {
        require(_weth != address(0), "!_weth");
        require(_keeper != address(0), "!_keeper");
        require(_vaultParams.cap > 0, "!_cap");
        require(_vaultParams.asset != address(0), "!_asset");

        WETH = _weth;
        keeper = _keeper;
        vaultParams = _vaultParams;

        vaultState.round = 1;
    }

    /************************************************
     *  PUBLIC STAKING
     ***********************************************/

    /**
     * @notice Stake the `asset` from msg.sender.
     * @param amount is the amount of `asset` to stake
     */
    function stake(uint256 amount) external nonReentrant {
        require(isPublic, "!public");
        require(amount > 0, "!amount");

        _stakeFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Stakes the `asset` from msg.sender added to `creditor`'s stake.
     * @notice Used for vault -> vault stakes on the user's behalf
     * @param amount is the amount of `asset` to stake
     * @param creditor is the address that can claim/withdraw staked amount
     */
    function stakeFor(uint256 amount, address creditor) external nonReentrant {
        require(isPublic, "!public");
        require(amount > 0, "!amount");
        require(creditor != address(0), "!creditor");

        _stakeFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Manages the stake receipts for a staker
     * @param amount is the amount of `asset` staked
     * @param creditor is the address to receieve the stake
     */
    function _stakeFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithStakedAmount = totalBalance() + amount;

        require(totalWithStakedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithStakedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Stake(creditor, amount, currentRound);

        Vault.StakeReceipt memory stakeReceipt = stakeReceipts[creditor];

        // If we have an unprocessed pending stake from the previous rounds, we have to process it.
        uint256 unredeemedShares = stakeReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[stakeReceipt.round],
            vaultParams.decimals
        );

        uint256 stakeAmount = amount;

        // If we have a pending stake in the current round, we add on to the pending stake
        if (currentRound == stakeReceipt.round) {
            uint256 newAmount = uint256(stakeReceipt.amount) + amount;
            stakeAmount = newAmount;
        }

        ShareMath.assertUint104(stakeAmount);

        stakeReceipts[creditor] = Vault.StakeReceipt({
            round: uint16(currentRound),
            amount: uint104(stakeAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /************************************************
     *  PRIVATE STAKING
     ***********************************************/

    /**
     * @notice Stakes the `asset` from msg.sender.
     * @notice msg.sender must be whitelisted
     * @param amount is the amount of `asset` to stake
     * @param proof is the merkle proof
     */
    function privateStake(
        uint256 amount,
        bytes32[] memory proof
    ) external nonReentrant {
        if (!isPublic) {
            require(
                proof.verify(
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Invalid proof"
            );
        }

        require(amount > 0, "!amount");

        _stakeFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /************************************************
     *  WITHDRAWALS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `StakeReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.StakeReceipt storage stakeReceipt = stakeReceipts[msg.sender];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(stakeReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = stakeReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        stakeReceipt.amount = uint104(receiptAmount - amount);
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending) - amount
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        _transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw and burn
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            stakeReceipts[msg.sender].amount > 0 ||
            stakeReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        require(currentRound > 1, "Cannot withdraw before round 1");

        uint256 withdrawAmount = ShareMath.sharesToAsset(
            numShares,
            roundPricePerShare[currentRound - 1],
            vaultParams.decimals
        );

        emit InitiateWithdraw(msg.sender, withdrawAmount, currentRound);

        ShareMath.assertUint128(withdrawAmount);
        withdrawals[msg.sender].amount += uint128(withdrawAmount);
        withdrawals[msg.sender].round = uint16(currentRound);

        _burn(msg.sender, numShares);

        totalQueuedWithdrawAmount = totalQueuedWithdrawAmount + withdrawAmount;
        currentQueuedWithdrawAmount =
            currentQueuedWithdrawAmount +
            withdrawAmount;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalAmount = withdrawal.amount;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalAmount > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].amount = 0;

        emit Withdraw(msg.sender, withdrawalAmount);

        _transferAsset(msg.sender, withdrawalAmount);

        totalQueuedWithdrawAmount = uint256(
            uint256(totalQueuedWithdrawAmount) - withdrawalAmount
        );
    }

    /************************************************
     *  REDEMPTIONS
     ***********************************************/

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.StakeReceipt memory stakeReceipt = stakeReceipts[msg.sender];

        // This handles the null case when stakeReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = stakeReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[stakeReceipt.round],
            vaultParams.decimals
        );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a stakeReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new stakes, we just zero it out for new stakes.
        if (stakeReceipt.round < currentRound) {
            stakeReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        stakeReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares - numShares
        );

        emit Redeem(msg.sender, numShares, stakeReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Rolls to the next round, finalizing prev round pricePerShare and minting new shares
     * @notice Keeper only stakes enough to fulfill withdraws and passes the true amount as 'currentBalance'
     * @notice Keeper should be a contract so currentBalance and the call to the func happens atomically
     * @param currentBalance is the amount of `asset` that is currently being used for strategy 
              + the amount in the contract right before the roll

     */
    function rollToNextRound(
        uint256 currentBalance
    ) external onlyKeeper nonReentrant {
        require(
            currentBalance >= uint256(vaultParams.minimumSupply),
            "Insufficient balance"
        );
        Vault.VaultState memory state = vaultState;
        uint256 currentRound = state.round;

        uint256 newPricePerShare = ShareMath.pricePerShare(
            totalSupply(),
            currentBalance - totalQueuedWithdrawAmount,
            state.totalPending,
            vaultParams.decimals
        );

        roundPricePerShare[currentRound] = newPricePerShare;

        vaultState.totalPending = 0;
        vaultState.round = uint16(currentRound + 1);

        currentQueuedWithdrawAmount = 0;

        uint256 mintShares = ShareMath.assetToShares(
            state.totalPending,
            newPricePerShare,
            vaultParams.decimals
        );

        _mint(address(this), mintShares);

        vaultState.lastLockedAmount = state.lockedAmount;

        uint256 lockedBalance = currentBalance - totalQueuedWithdrawAmount;

        ShareMath.assertUint104(lockedBalance);

        vaultState.lockedAmount = uint104(lockedBalance);

        IERC20(vaultParams.asset).safeTransfer(
            keeper,
            IERC20(vaultParams.asset).balanceOf(address(this)) -
                totalQueuedWithdrawAmount
        );
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function _transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the vault to public or private
     * @param _isPublic is the new public state
     */
    function setPublic(bool _isPublic) external onlyOwner {
        isPublic = _isPublic;
    }

    /**
     * @notice Sets the merkle root for the private whitelist
     * @param _merkleRoot is the new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets a new cap for stakes
     * @param newCap is the new cap for stakes
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Sets the new vault parameters
     */
    function setVaultParams(
        Vault.VaultParams memory newVaultParams
    ) external onlyOwner {
        require(newVaultParams.cap > 0, "!newCap");
        require(newVaultParams.asset != address(0), "!newAsset");
        vaultParams = newVaultParams;
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount) +
            IERC20(vaultParams.asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the asset balance held on the vault for the account not
               accounting for current round stakes
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(
        address account
    ) external view returns (uint256) {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare = ShareMath.pricePerShare(
            totalSupply(),
            totalBalance() - totalQueuedWithdrawAmount,
            vaultState.totalPending,
            _decimals
        );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount + heldByVault;
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(
        address account
    ) public view returns (uint256 heldByAccount, uint256 heldByVault) {
        Vault.StakeReceipt memory stakeReceipt = stakeReceipts[account];

        if (stakeReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares = stakeReceipt.getSharesFromReceipt(
            vaultState.round,
            roundPricePerShare[stakeReceipt.round],
            vaultParams.decimals
        );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance() - totalQueuedWithdrawAmount,
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice returns if account can stake
     * @param account is the account to check
     * @param proof is the merkle proof
     */
    function canStake(
        address account,
        bytes32[] memory proof
    ) external view returns (bool) {
        return
            isPublic ||
            proof.verify(merkleRoot, keccak256(abi.encodePacked(account)));
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }

    function round() external view returns (uint256) {
        return vaultState.round;
    }

    receive() external payable {}
}
