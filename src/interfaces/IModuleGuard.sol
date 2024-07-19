// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

interface IModuleGuard is IERC165 {
    function checkModuleTransaction(address to, uint256 value, bytes memory data, uint8 operation, address module)
        external
        returns (bytes32 moduleTxHash);
    function checkAfterModuleExecution(bytes32 txHash, bool success) external;
}
