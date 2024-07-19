// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

uint256 constant MODULE_GUARD_STORAGE_SLOT = 0xb104e0b93118902c651344349b610029d694cfdec91c589c91ebafbcd0289947;
uint256 constant TRANSACTION_GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

interface ISafe {
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);
}
