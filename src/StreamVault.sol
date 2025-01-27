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
import {IStableWrapper} from "./interfaces/IStableWrapper.sol";
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

    /************************************************
     *  STATE
     ***********************************************/
    /// @notice Stores the user's pending stake for the round
    mapping(address => Vault.StakeReceipt) public stakeReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their StakeReceipt.stakeAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice role in charge of weekly vault operations such as rollToNextRound
    // no access to critical vault changes
    address public keeper;

    /// @notice address of the stable wrapper contract
    address public stableWrapper;

    /// @notice the total supply of shares across all chains
    uint256 public omniTotalSupply;

    /************************************************
     *  EVENTS
     ***********************************************/
    event Stake(address indexed account, uint256 amount, uint256 round);

    event Unstake(address indexed account, uint256 amount, uint256 round);

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
     * @param _keeper is the role that will handle funds and advancing rounds
     * @param _tokenName is the token name of the share ERC-20
     * @param _tokenSymbol is the token symbol of the share ERC-20
     * @param _vaultParams is the `VaultParams` struct with general vault data
     */
    constructor(
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _stableWrapper,
        Vault.VaultParams memory _vaultParams
    ) ReentrancyGuard() Ownable(msg.sender) ERC20(_tokenName, _tokenSymbol) {
        require(_keeper != address(0), "!_keeper");
        require(_vaultParams.cap > 0, "!_cap");
        require(_vaultParams.asset != address(0), "!_asset");

        keeper = _keeper;
        stableWrapper = _stableWrapper;
        vaultParams = _vaultParams;

        vaultState.round = 1;
    }
    /************************************************
     *  Wrapper functions
     ***********************************************/

    /**
     * @notice Deposits assets and stakes them in a single transaction
     * @param amount Amount of assets to deposit and stake
     */
    function depositAndStake(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        IStableWrapper(stableWrapper).depositFrom(msg.sender, amount);

        // Then stake the wrapped tokens
        stakeFor(amount, msg.sender);
    }

    /**
     * @notice Unstakes tokens and initiates withdrawal in a single transaction
     * @param numShares Number of shares to unstake
     */
    function unstakeAndWithdraw(uint256 numShares) external nonReentrant {
        // First unstake the tokens
        _unstake(numShares);

        // Then initiate withdrawal in the wrapper
        IStableWrapper(stableWrapper).initiateWithdrawalFor(
            msg.sender,
            uint224(numShares)
        );
    }

    /**
     * @notice Performs instant unstake and initiates withdrawal in a single transaction
     * @param amount Amount to unstake instantly
     */
    function instantUnstakeAndWithdraw(uint256 amount) external nonReentrant {
        // First perform instant unstake
        _instantUnstake(amount);

        // Then initiate withdrawal in the wrapper
        IStableWrapper(stableWrapper).initiateWithdrawalFor(
            msg.sender,
            uint224(amount)
        );
    }

    /************************************************
     *  PUBLIC STAKING
     ***********************************************/

    /**
     * @notice Stake the `asset` from msg.sender.
     * @param amount is the amount of `asset` to stake
     */
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        require(IStableWrapper(stableWrapper).allowIndependence(), "!allowIndependence");

        _stakeForInternal(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice External wrapper for staking on behalf of another address
     * @param amount is the amount of `asset` to stake
     * @param creditor is the address that can claim/withdraw staked amount
     */
    function stakeFor(uint256 amount, address creditor) public nonReentrant {
        require(IStableWrapper(stableWrapper).allowIndependence(), "!allowIndependence");
        _stakeFor(amount, creditor);
    }


    /**
     * @notice Stakes the `asset` from msg.sender added to `creditor`'s stake.
     * @notice Used for vault -> vault stakes on the user's behalf
     * @param amount is the amount of `asset` to stake
     * @param creditor is the address that can claim/withdraw staked amount
     */
    function _stakeFor(uint256 amount, address creditor) internal nonReentrant {
        require(amount > 0, "!amount");
        require(creditor != address(0), "!creditor");

        _stakeForInternal(amount, creditor);

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
    function _stakeForInternal(uint256 amount, address creditor) private {
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
     *  WITHDRAWALS
     ***********************************************/

     /**
     * @notice External wrapper for instant unstaking
     * @param amount is the amount to withdraw
     */
    function instantUnstake(uint256 amount) external nonReentrant {

        require(IStableWrapper(stableWrapper).allowIndependence(), "!allowIndependence");

        _instantUnstake(amount);
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `StakeReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function _instantUnstake(uint256 amount) internal nonReentrant {
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
     * @notice External wrapper for unstaking shares
     * @param numShares is the number of shares to withdraw and burn
     */
    function unstake(uint256 numShares) external nonReentrant {

        require(IStableWrapper(stableWrapper).allowIndependence(), "!allowIndependence");

        _unstake(numShares);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw and burn
     */
    function _unstake(uint256 numShares) internal nonReentrant {
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

        emit Unstake(msg.sender, withdrawAmount, currentRound);

        _burn(msg.sender, numShares);

        omniTotalSupply -= numShares;

        IERC20(vaultParams.asset).safeTransfer(msg.sender, withdrawAmount);
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
            omniTotalSupply,
            currentBalance,
            state.totalPending,
            vaultParams.decimals
        );

        roundPricePerShare[currentRound] = newPricePerShare;

        vaultState.totalPending = 0;
        vaultState.round = uint16(currentRound + 1);

        uint256 mintShares = ShareMath.assetToShares(
            state.totalPending,
            newPricePerShare,
            vaultParams.decimals
        );

        _mint(address(this), mintShares);

        omniTotalSupply += mintShares;

        uint256 balance = totalBalance();

        if (currentBalance > balance) {
            uint256 amountToMint = currentBalance - balance;
            IStableWrapper(stableWrapper).permissionedMint(
                address(this),
                amountToMint
            );
        } else {
            uint256 amountToBurn = balance - currentBalance;
            IStableWrapper(stableWrapper).permissionedBurn(
                address(this),
                amountToBurn
            );
        }
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function _transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  SETTERS
     ***********************************************/

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
     * @notice Returns the vault's total balance of Stream wrapped tokens
     * @return total balance of the vault
     */
    function totalBalance() public view returns (uint256) {
        return IERC20(vaultParams.asset).balanceOf(address(this));
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
            omniTotalSupply,
            totalBalance(),
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
                omniTotalSupply,
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
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
