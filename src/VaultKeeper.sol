// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StreamVault} from "./StreamVault.sol";
import {Vault} from "./lib/Vault.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * @title - VaultKeeper
 * @notice - This contract is responsible for rolling rounds and managing vaults
 * @notice - This contract takes the place of the Keeper in StreamVault to avoid front-runs
 */
contract VaultKeeper {
    address public coordinator;
    mapping(string => address) public vaults;
    mapping(string => address) public managers;
    /*
     * @notice - Constructor
     * @notice - order matters in the list of vaults, managers, and tickers
     * @param _tickers - List of vault tickers
     * @param _managers - List of managers
     * @param _vaults - List of vaults
     */
    constructor(
        string[] memory _tickers,
        address[] memory _managers,
        address[] memory _vaults
    ) {
        require(
            _tickers.length == _managers.length &&
                _tickers.length == _vaults.length,
            "VaultKeeper: Invalid input"
        );

        coordinator = msg.sender;

        for (uint8 i = 0; i < _tickers.length; ) {
            vaults[_tickers[i]] = _vaults[i];
            managers[_tickers[i]] = _managers[i];
            unchecked {
                ++i;
            }
        }
    }

    /************************************************
     *  ROLLING ROUND
     ***********************************************/

    /**
     * @notice - Roll round for a list of vaults. Vaults should be added to state before rolling round
     * @param ticker - vault ticker
     * @param lockedBalance - locked balance for vault
     */
    function rollRound(string calldata ticker, uint256 lockedBalance) external {
        require(managers[ticker] == msg.sender, "VaultKeeper: Invalid manager");
        address vault = vaults[ticker];
        require(vault != address(0), "VaultKeeper: Invalid vault");
        _rollRound(lockedBalance, vault);
    }

    /************************************************
     *  MANAGEMENT
     ***********************************************/
    function addVault(
        string calldata ticker,
        address vault,
        address manager
    ) external {
        require(
            vaults[ticker] == address(0),
            "VaultKeeper: Vault already exists"
        );
        require(
            managers[ticker] == address(0),
            "VaultKeeper: Manager already exists"
        );
        require(manager != address(0), "VaultKeeper: Invalid manager");
        require(vault != address(0), "VaultKeeper: Invalid vault");
        require(coordinator == msg.sender, "VaultKeeper: Invalid caller");

        vaults[ticker] = vault;
        managers[ticker] = manager;
    }

    function removeVault(string calldata ticker) external {
        require(
            managers[ticker] == msg.sender || coordinator == msg.sender,
            "VaultKeeper: Invalid manager"
        );
        delete vaults[ticker];
    }

    function transferOwnership(
        string calldata ticker,
        address newManager
    ) external {
        require(
            managers[ticker] == msg.sender || coordinator == msg.sender,
            "VaultKeeper: Invalid manager"
        );
        managers[ticker] = newManager;
    }

    function transferCoordinator(address newCoordinator) external {
        require(coordinator == msg.sender, "VaultKeeper: Invalid coordinator");
        coordinator = newCoordinator;
    }

    /*
     * @notice - Emergency withdraw assets from the contract
     * @param token - Address of the token to withdraw. 0x0 for native token
     * @param amount - Amount to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        require(coordinator == msg.sender, "VaultKeeper: Invalid coordinator");
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            ERC20(token).transfer(msg.sender, amount);
        }
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function _rollRound(uint256 _lockedBalance, address _vault) internal {
        StreamVault vault = StreamVault(payable(_vault));
        (, address _asset, , ) = vault.vaultParams();
        ERC20 asset = ERC20(_asset);
        uint256 currBalance = asset.balanceOf(address(vault)) + _lockedBalance;
        _transferAssets(address(asset), vault, currBalance);

        vault.rollToNextRound(currBalance);
        asset.transfer(msg.sender, asset.balanceOf(address(this)));
    }

    function _transferAssets(
        address asset,
        StreamVault vault,
        uint256 currBalance
    ) internal {
        uint256 queuedWithdrawAmount = vault.getCurrQueuedWithdrawAmount(
            currBalance
        );

        uint256 balance = ERC20(asset).balanceOf(address(vault));

        if (balance >= queuedWithdrawAmount) {
            return;
        }

        uint256 amountToTransfer = queuedWithdrawAmount - balance;

        uint256 lastQueuedWithdrawAmount = vault.lastQueuedWithdrawAmount();

        require(
            amountToTransfer <= queuedWithdrawAmount - lastQueuedWithdrawAmount,
            "VaultKeeper: Assets to transfer is greater than the amount to withdraw for current round"
        );

        ERC20(asset).transferFrom(
            msg.sender,
            address(vault),
            amountToTransfer
        );

        require(
            ERC20(asset).balanceOf(address(vault)) >= queuedWithdrawAmount,
            "VaultKeeper: Not enough assets"
        );
    }
}
