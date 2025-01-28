<h1 align="center"> Stream V2 </h1>

## What is Stream V2?
Stream V2 constructs yield bearing vaults. There are two core pieces of infrasturcture:

- The first is a simple wrapper contract which wraps the underlying token of the vault (i.e USDC for the StreamUSDC vault)
- The second is the vault contract which allows users to stake this wrapped token and earn their proportional yield from wrapping the underlying token. This is represented through a share token

The structure is similar [Ethena's USDe and sUSDe](https://docs.ethena.fi/) structure, however the yield is not generated from a carry trade - yet remains delta nuetral

## Implementation
The token wrapper contract is called `StableWrapper`. Upon wrapping the token, the underlying deposited token will be used for yield farming while the user receives a 1-to-1 wrapped version of this token. The user will not be entitled to any yield unless they stake in the vault contract. To unwrap this token, there will be a delay in order to allow time for the vault keeper to deposit the underlying token back into the contract to allow for withdrawals to complete


NOTE:
   At the start all tokens will be required to be autostaked so all users will be entitled to yield. This is handled through the `allowIndependence` flag on the `StableWrapper` contract and may change in the future which will allow the user to hold the wrapped token in itself

Upon staking the wrapped token (defined in the `StreamVault` contract), the user will receive a share representing their stake in the vault. Holding this share token will entitle the user to receive the yield generated from their funds. This share token is non rebasing

Both the wrapped version of the token and the share token are both natively bridgeable through [LayerZero](https://docs.layerzero.network/v2)

## Yield Distribution
Yield is distributed once a day, which is set by the `vaultKeeper` on the call to `rollToNextRound()` in the `StreamVault` contract. At these discrete moments in time, yield is distributed evenly to all share token holders. When the round is rolled a call is made from the `StreamVault` contract to the `StableWrapper` contract to mint/burn the correct amount of wrapped tokens into the `StreamVault` contract to maintain proper accounting of the yield.


NOTE: 
  Yield can be both positive or negative at any given roll


## Risks
Upon wrapping the token, the funds will be held in the `StableWrapper` contract where they are free to be withdrawn from the vault keeper. The vault keeper manages funds in a separate multisig which is used to more easily farm different yield opportunities (managing it through the contract reduces flexibility on the yield opportunities). The vault keeper wallet will be public and it's positions will be easily monitored through a dashboard 

## Contracts and Functions

### StableWrapper
Implemented as 1-to-1 wrapper contract with delayed withdrawals to allow the vault keeper to deposit funds (taken out of the strategy) back into the contract. The wrapped version of the token is bridgeable through LayerZero. While `allowIndependence` is false, only the `StreamVault` contract has the privelege to deposit on for the user to ensure funds get auto staked in the `StreamVault` contract

#### depositToVault()
Only callable by the `StreamVault`. Used to transfer the underlying token to the `StableWrapper` contract, and mints the wrapped token directly to the vault in order to be auto staked. Emits a `DepositToVault` event

#### initiateWithdrawalFromVault()
Only callable by the `StreamVault`. Used to burn the wrapped token amount (transfered to the `StableWrapper` contract from the `StreamVault` contract before calling this func). This function creates a withdrawal receipt for the amount being withdrawn which can be completed through `completeWithdrawal` at a later epoch. Emits a `WithdrawalInitiated` event

#### deposit()
Only callable when `allowIndependence` is true. Contains the same functionality as `depositToVault()`, however it mints to the caller of the contract and does not auto stake. Emits an `Deposit` event

#### initiateWithdrawal()
Only callable when `allowIndependence` is true. Contains the same functionality as `initiateWithdrawalFromVault()`, however it burns from `msg.sender` instead of from the contract itself. Emits an `WithdrawalInitiated` event

#### completeWithdrawal()
This function is used to complete a withdrawal which transfers the underlying token from the contract back to specified address. This can only be called after either `initiateWithdrawal()` or `initiateWithdrawalFromVault()` has been called and an epoch has passed . Emits a `Withdrawn` event.

#### permissionedMint()
Only callable by the `StreamVault` contract. Used to mint more wrapped token into the stream vault to account for positive yield. Emits a `PermissionedMint` event.

#### permissionedBurn()
Only callable by the `StreamVault` contract. Used to burn wrapped tokens owned by the `StreamVault` to account for negative yield. Emits a `PermissionedBurn` event.

#### transferAsset()
Only callable by the vault keeper. Used to withdraw the funds that have been wrapped to the keepr to be used for yield farming. Emits an `AssetTransferred` event.

### StreamVault
The `StreamVault` contract is used to stake wrapped Stream tokens in order to be entitled for the yield that is being generated from wrapping the underlying tokens into Stream tokens. When staking tokens, a share token will be received that represents the amount of the token pool the user owns. The share token is non rebasing and can be natively bridged through LayerZero. The vault operates on a round-by-round basis where each round (one round per day), yield is distributed (either positive or negative), and distributed proportionally to all share holders. In order to keep the accounting sound, the `StreamVault` has special permissions on the `StableWrapper` contract to mint new tokens for positive yield, or burn tokens to represent negative yield on every roll of the round. Unlike the `StableWrapper` contract, shares can be burned immediately and the Stream wrapped tokens will be received. However if `allowIndependence` is false, when unstaking, the wrapped tokens will be auto queued for withdrawal on the `StableWrapper` contract which is not immediate as explained above. Users do not receive yield for either the round they deposit it and the round they withdraw in. When depositing, shares aren't minted until the round is rolled, and therefore the shares are held by the contract unless they are redeemed by the user by calling `redeem()`. If a user stakes in round n, and changes their mind and wishes to unstake in round n, they can always instantly withdraw by calling `instantUnstake()`, however they will no receive yield for that round.

#### depositAndStake()
Will deposit the underlying token into the `StabelWrapper` contract, and auto stake the tokens into the vault. A staking receipt will be generated for the user. Emits both a `DepositToVault` and `Stake` event

#### unstakeAndWithdraw()
Will unstake the tokens: burns the shares, calculates how much wrapped tokens the shares map to, and additionally queue the withdrawal on the `StableWrapper` contract. Emits both a `WithdrawalInitiated` and an `Unstake` event.

#### instantUnstakeAndWithdraw()
Will instantly unstake and queue tokens for withdrawal on the `StableWrapper` contract. This is only callable for withdrawing wrapped tokens in the same round they were staked. Emits both a `WithdrawalInitiated` and an `InstantWithdraw` event.
 
#### stake()
Only callable when `allowIndepedence` on the `StableWrapper` contract is true. This will transfer the wrapped shared token into the `StreamVault` contract and create a stake receipt for the user. Shares will be minted on the next roll round, where they will be by default held by the contract but can always be redeemed. Emits a `Stake` event.

#### unstake()
Only callable when `allowIndepedence` on the `StableWrapper` contract is true. This will burn the shares, and transfer the corresponding amount of Stream wrapped tokens to the user. This can only be called if a user has previously staked and at least one round has passed. Emits an `Unstake` event.

#### instantUnstake()
Only callable when `allowIndepedence` on the `StableWrapper` contract is true. This will simply transfer back the amount of wrapped Stream tokens that were staked in the same round. Emits an `InstantUnstake` event.

#### redeem()
Used to redeem shares that a user owns but is held by the `StreamVault` contract. Emits a `Redeem` event.

#### maxRedeem()
Calls the above function, but with the max amount of shares the user has available.

#### rollToNextRound()
A function only the keeper can call in order to roll one round to the next. The user inputs a yield amount which is how much of the underlying token was generated in yield (either positive or negative). This is used for the following:

1) Mint shares for the current rounds staking requests
2) Mints or burns the wrapped Stream token to account for the yield for the round

Emits a `RoundRolled` event.

#### accountVaultBalance()
Getter for the amount of wrapped Stream tokens the user owns based on their shares.

#### shares()
Getter for the amount of shares the user owns (both held by the user and by the vault).

#### shareBalances()
Getter for the amount of shares the user owns, both held by the user and by the vault, but returned separately.