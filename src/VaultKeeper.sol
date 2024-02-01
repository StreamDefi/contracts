// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StreamVault} from "./StreamVault.sol";
import {Vault} from "./lib/Vault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultKeeper is Ownable {
    mapping(string => address) public vaults;

    constructor() Ownable(msg.sender) {}

    function rollRound(
        string[] calldata tickers,
        uint256[] calldata lockedBalances
    ) external onlyOwner {
        require(
            tickers.length == lockedBalances.length,
            "VaultKeeper: Invalid input"
        );
        for (uint256 i = 0; i < tickers.length; i++) {
            _rollRound(tickers[i], lockedBalances[i]);
        }
    }

    function _rollRound(string memory ticker, uint256 lockedBalance) internal {
        StreamVault vault = StreamVault(payable(vaults[ticker]));
        (, address _asset, , ) = vault.vaultParams();
        ERC20 asset = ERC20(_asset);
        require(
            keccak256(abi.encodePacked(asset.symbol())) ==
                keccak256(abi.encodePacked(ticker)),
            "VaultKeeper: Invalid ticker"
        );
        uint256 currBalance = asset.balanceOf(address(vault)) + lockedBalance;
        uint256 queuedWithdrawShares = _enoughAssets(address(asset), vault);
        asset.transferFrom(owner(), address(vault), queuedWithdrawShares);
        vault.rollToNextRound(currBalance);
        asset.transfer(owner(), asset.balanceOf(address(this)));
    }

    function _enoughAssets(
        address asset,
        StreamVault vault
    ) internal view returns (uint256) {
        uint256 queuedWithdrawShares = vault.currentQueuedWithdrawShares();
        require(
            ERC20(asset).balanceOf(address(this)) >= queuedWithdrawShares,
            "VaultKeeper: Not enough assets"
        );
        return queuedWithdrawShares;
    }

    function addVault(
        string calldata ticker,
        address vault
    ) external onlyOwner {
        vaults[ticker] = vault;
    }

    function removeVault(string calldata ticker) external onlyOwner {
        delete vaults[ticker];
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            ERC20(token).transfer(owner(), amount);
        }
    }
}
