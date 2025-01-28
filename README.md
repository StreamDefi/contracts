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
Yield is distributed once a day, which is set by the `vaultKeeper` on the call to `rollToNextRound()` in the `StreamVault` contract. At these discrete moments in time, yield is distributed evenly to all share token holders.


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
This function is used to complete a withdrawal which transfers the underlying token from the contract back to specified address. This can only be called after either `initiateWithdrawal()` or `initiateWithdrawalFromVault()` has been called and an epoch has passed 