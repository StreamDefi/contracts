// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import {MyOFT} from "../src/MyOFT.sol";
// import {IOFT, SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
// import {StableWrapper} from "../src/StableWrapper.sol";
// import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
// import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {StreamVault} from "../src/StreamVault.sol";
// import {Vault} from "../src/lib/Vault.sol";

// contract OFTMock is MyOFT {
//     constructor(
//         string memory _name,
//         string memory _symbol,
//         address _lzEndpoint,
//         address _delegate,
//         uint8 _underlyingDecimals
//     ) MyOFT(_name, _symbol, _lzEndpoint, _delegate, _underlyingDecimals) {}

//     function mint(address to, uint256 amount) public {
//         _mint(to, amount);
//     }
// }

// contract StableWrapperMock is StableWrapper {
//     constructor(
//         address _asset,
//         string memory _name,
//         string memory _symbol,
//         uint8 _underlyingDecimals,
//         address _keeper,
//         address _lzEndpoint,
//         address _delegate
//     )
//         StableWrapper(
//             _asset,
//             _name,
//             _symbol,
//             _underlyingDecimals,
//             _keeper,
//             _lzEndpoint,
//             _delegate
//         )
//     {}
// }

// contract ERC20Mock is ERC20 {
//     constructor(
//         string memory _name,
//         string memory _symbol
//     ) ERC20(_name, _symbol) {}

//     function mint(address _to, uint256 _amount) public {
//         _mint(_to, _amount);
//     }
// }

// contract OFTTest is Test, TestHelperOz5 {
//     using OptionsBuilder for bytes;

//     uint32 internal ethEid = 1;
//     uint32 internal arbitrumEid = 2;

//     address admin = makeAddr("admin");
//     address userB = makeAddr("userB");

//     function setUp() public override {
//         super.setUp();
//         setUpEndpoints(1, LibraryType.UltraLightNode);
//         setUpEndpoints(2, LibraryType.UltraLightNode);
//     }
//     // forge test --match-test testOFT --watch -vv
//     function test_OFT() public {
//         vm.startPrank(admin);
//         vm.deal(admin, 1000 ether);

//         ERC20Mock usdt = new ERC20Mock("USDT", "USDT");

//         uint8 decimals = 6;
//         uint104 amountToDeposit = uint104(2 ** 64); // ~ $18.

//         StreamVault streamVault = new StreamVault(
//             "StreamVault",
//             "SV",
//             address(0x123),
//             address(endpoints[ethEid]),
//             admin,
//             Vault.VaultParams(decimals, 10e10, 1e7 ether)
//         );

//         StableWrapper stableWrapper = new StableWrapper(
//             address(usdt),
//             "StableWrapper",
//             "SW",
//             decimals,
//             address(streamVault),
//             address(endpoints[ethEid]),
//             admin
//         );
//         streamVault.setStableWrapper(address(stableWrapper));
//         OFTMock oftA = new OFTMock(
//             "OFTA",
//             "OFTA",
//             address(endpoints[arbitrumEid]),
//             admin,
//             decimals
//         );

//         console.log(
//             "decimalConversionRate",
//             stableWrapper.decimalConversionRate()
//         );
//         console.log("sharedDecimals", stableWrapper.sharedDecimals());
//         console.log("decimals", stableWrapper.decimals());

//         address[] memory ofts = new address[](2);
//         ofts[0] = address(streamVault);
//         ofts[1] = address(oftA);
//         wireOApps(ofts);

//         // mint USDT to admin
//         usdt.mint(admin, amountToDeposit);

//         // depositAndStake
//         usdt.approve(address(stableWrapper), amountToDeposit);
//         streamVault.depositAndStake(amountToDeposit, admin);

//         vm.warp(block.timestamp + 1 days);

//         streamVault.rollToNextRound(0, false);
//         console.log("roundPricePerShare", streamVault.roundPricePerShare(1));
//         console.log("omniTotalSupply", streamVault.omniTotalSupply());

//         bytes memory options = OptionsBuilder
//             .newOptions()
//             .addExecutorLzReceiveOption(200000, 0);

//         SendParam memory _sendParam = SendParam({
//             dstEid: arbitrumEid,
//             to: addressToBytes32(address(userB)),
//             amountLD: amountToDeposit,
//             minAmountLD: amountToDeposit,
//             extraOptions: options,
//             composeMsg: new bytes(0),
//             oftCmd: new bytes(0)
//         });

//         MessagingFee memory _fee = streamVault.quoteSend(_sendParam, false);

//         printStakeReceipt(streamVault, admin);
//         streamVault.bridgeWithRedeem{value: _fee.nativeFee}(
//             _sendParam,
//             _fee,
//             payable(admin)
//         );
//         printStakeReceipt(streamVault, admin);

//         console.log("userB balance before", oftA.balanceOf(userB));

//         verifyPackets(arbitrumEid, addressToBytes32(address(oftA)));

//         console.log("userB balance after", oftA.balanceOf(userB));
//     }

//     function printStakeReceipt(
//         StreamVault streamVault,
//         address user
//     ) public view {
//         (uint16 round, uint104 amount, uint128 unredeemedShares) = streamVault
//             .stakeReceipts(user);
//         console.log("stakeReceipt for user", user);
//         console.log("stakeReceipt.amount", amount);
//         console.log("unredeemedShares", unredeemedShares);
//     }
// }
