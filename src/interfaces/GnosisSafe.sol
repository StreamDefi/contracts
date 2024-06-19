// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface GnosisSafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success);
}
