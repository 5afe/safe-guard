// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

interface ITransactionGuard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;
    function checkAfterExecution(bytes32 hash, bool success) external;
}
