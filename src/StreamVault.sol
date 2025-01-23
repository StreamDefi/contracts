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
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {SendParam, OFTLimit, OFTReceipt, OFTFeeDetail, MessagingReceipt, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/**
 * @title StreamVault
 * @notice A vault that allows users to deposit and withdraw from an off-chain managed Stream strategy
 * @notice Users receive shares for their deposits, which can be redeemed for assets
 * @notice The vault is managed by a keeper, who is responsible for rolling to the next round
 * @notice The rounds will be rolled over on a weekly basis
 */

contract StreamVault is OFT, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ShareMath for Vault.DepositReceipt;
    using MerkleProofLib for bytes32[];

    /************************************************
     *  STATE
     ***********************************************/
    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice The amount of 'asset' that was queued for withdrawal in the last round
    uint256 public lastQueuedWithdrawAmount;

    /// @notice The amount of shares that are queued for withdrawal in the current round
    uint256 public currentQueuedWithdrawShares;

    /// @notice role in charge of weekly vault operations such as rollToNextRound
    // no access to critical vault changes
    address public keeper;

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice To safely calculate share math, we must keep track of share tokens on all chains
    uint256 public totalOmnichainSupply;

    /// @notice private or public
    bool public isPublic;

    /// @notice merkle root for private whitelist
    bytes32 public merkleRoot;

    /************************************************
     *  EVENTS
     ***********************************************/
    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );
    event Withdraw(address indexed account, uint256 amount, uint256 shares);

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
        address _lzEndpoint,
        address _delegate,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams memory _vaultParams
    )
        ReentrancyGuard()
        OFT(_tokenName, _tokenSymbol, _lzEndpoint, _delegate)
        Ownable(msg.sender)
    {
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
     *  PUBLIC DEPOSITS
     ***********************************************/

    /**
     * @notice Deposits the native asset from msg.sender.
     */
    function depositETH() external payable nonReentrant {
        require(isPublic, "!public");
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(isPublic, "!public");
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(
        uint256 amount,
        address creditor
    ) external nonReentrant {
        require(isPublic, "!public");
        require(amount > 0, "!amount");
        require(creditor != address(0), "!creditor");

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the native asset  from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositETHFor(address creditor) external payable nonReentrant {
        require(isPublic, "!public");
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");
        require(creditor != address(0), "!creditor");

        _depositFor(msg.value, creditor);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Manages the deposit receipts for a depositer
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance() + amount;

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[depositReceipt.round],
            vaultParams.decimals
        );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount) + amount;
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /************************************************
     *  PRIVATE DEPOSITS
     ***********************************************/

    /**
     * @notice Deposits the native asset from msg.sender.
     * @notice msg.sender must be whitelisted
     * @param proof is the merkle proof
     */
    function privateDepositETH(
        bytes32[] memory proof
    ) external payable nonReentrant {
        if (!isPublic) {
            require(
                proof.verify(
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Invalid proof"
            );
        }
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @notice msg.sender must be whitelisted
     * @param amount is the amount of `asset` to deposit
     * @param proof is the merkle proof
     */
    function privateDeposit(
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

        _depositFor(amount, msg.sender);

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
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt = depositReceipts[
            msg.sender
        ];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount - amount);
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending) - amount
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        _transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal memory withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares + numShares;
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);

        currentQueuedWithdrawShares = currentQueuedWithdrawShares + numShares;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares) - withdrawalShares
        );

        uint256 withdrawAmount = ShareMath.sharesToAsset(
            withdrawalShares,
            roundPricePerShare[withdrawalRound],
            vaultParams.decimals
        );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        totalOmnichainSupply -= withdrawalShares;

        require(withdrawAmount > 0, "!withdrawAmount");
        _transferAsset(msg.sender, withdrawAmount);

        lastQueuedWithdrawAmount = uint256(
            uint256(lastQueuedWithdrawAmount) - withdrawAmount
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
        Vault.DepositReceipt memory depositReceipt = depositReceipts[
            msg.sender
        ];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[depositReceipt.round],
            vaultParams.decimals
        );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares - numShares
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Rolls to the next round, finalizing prev round pricePerShare and minting new shares
     * @notice Keeper only deposits enough to fulfill withdraws and passes the true amount as 'currentBalance'
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
            totalOmnichainSupply - state.queuedWithdrawShares,
            currentBalance - lastQueuedWithdrawAmount,
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

        totalOmnichainSupply += mintShares;

        uint256 queuedWithdrawAmount = lastQueuedWithdrawAmount +
            ShareMath.sharesToAsset(
                currentQueuedWithdrawShares,
                newPricePerShare,
                vaultParams.decimals
            );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares = uint256(state.queuedWithdrawShares) +
            currentQueuedWithdrawShares;

        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        vaultState.lastLockedAmount = state.lockedAmount;

        uint256 lockedBalance = currentBalance - queuedWithdrawAmount;

        ShareMath.assertUint104(lockedBalance);

        vaultState.lockedAmount = uint104(lockedBalance);

        IERC20(vaultParams.asset).safeTransfer(
            keeper,
            IERC20(vaultParams.asset).balanceOf(address(this)) -
                queuedWithdrawAmount
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
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
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
     *  OFT HANDLERS
     ***********************************************/
    /**
     * @dev Executes the send operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The calculated fee for the send() operation.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds.
     * @return msgReceipt The receipt for the send operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    )
        external
        payable
        virtual
        override
        returns (
            MessagingReceipt memory msgReceipt,
            OFTReceipt memory oftReceipt
        )
    {
        /// @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            msg.sender,
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        /// @dev ensure these are equal for share math
        require(
            amountSentLD == amountReceivedLD,
            "Amount sent must equal amount received"
        );

        /// @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(
            _sendParam,
            amountReceivedLD
        );

        /// @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(
            _sendParam.dstEid,
            message,
            options,
            _fee,
            _refundAddress
        );
        /// @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(
            msgReceipt.guid,
            _sendParam.dstEid,
            msg.sender,
            amountSentLD,
            amountReceivedLD
        );
    }

    // /**
    //  * @dev Credits tokens to the specified address.
    //  * @param _to The address to credit the tokens to.
    //  * @param _amountLD The amount of tokens to credit in local decimals.
    //  * @dev _srcEid The source chain ID.
    //  * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
    //  */
    // function _credit(
    //     address _to,
    //     uint256 _amountLD,
    //     uint32 /*_srcEid*/
    // ) internal virtual override returns (uint256 amountReceivedLD) {
    //     if (_to == address(0x0)) _to = address(0xdead); // _mint(...) does not support address(0x0)
    //     // @dev Default OFT mints on dst.
    //     _mint(_to, _amountLD);
    //     // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
    //     return _amountLD;
    // }

    /************************************************
     *  GETTERS
     ***********************************************/

    /** 
    * @notice Returns the current amount of `asset` that is queued for withdrawal in the current round
    * @param currentBalance is the amount of `asset` that is currently being used for strategy 
            + the amount in the contract right now
    * @return the amount of `asset` that is queued for withdrawal in the current round
    */
    function getCurrQueuedWithdrawAmount(
        uint256 currentBalance
    ) public view returns (uint256) {
        Vault.VaultState memory state = vaultState;
        uint256 newPricePerShare = ShareMath.pricePerShare(
            totalOmnichainSupply - state.queuedWithdrawShares,
            currentBalance - lastQueuedWithdrawAmount,
            state.totalPending,
            vaultParams.decimals
        );
        return (lastQueuedWithdrawAmount +
            ShareMath.sharesToAsset(
                currentQueuedWithdrawShares,
                newPricePerShare,
                vaultParams.decimals
            ));
    }

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
               accounting for current round deposits
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(
        address account
    ) external view returns (uint256) {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare = ShareMath.pricePerShare(
            totalOmnichainSupply,
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
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
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
                totalOmnichainSupply,
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice returns if account can deposit
     * @param account is the account to check
     * @param proof is the merkle proof
     */
    function canDeposit(
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

    function sharedDecimals() public view override returns (uint8) {
        return decimals();
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
