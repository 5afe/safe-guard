// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {IERC165} from "./interfaces/IERC165.sol";
import {IModuleGuard} from "./interfaces/IModuleGuard.sol";
import {ISafe, MODULE_GUARD_STORAGE_SLOT, TRANSACTION_GUARD_STORAGE_SLOT} from "./interfaces/ISafe.sol";
import {ITransactionGuard} from "./interfaces/ITransactionGuard.sol";

contract SafeGuard is IModuleGuard, ITransactionGuard {
    struct Account {
        bool initialized;
        bytes32 configurationHash;
        uint256 timelock;
    }

    struct Authorization {
        address addr;
        bool authorized;
    }

    struct Configuration {
        Authorization[] delegates;
        Authorization[] modules;
    }

    uint256 public constant TIMELOCK = 7 days;
    bytes32 public constant DISABLE = bytes32(uint256(keccak256("disable")) - 1);

    mapping(address safe => Account account) public accounts;
    mapping(address delegate => mapping(address safe => bool authorized)) public delegates;
    mapping(address module => mapping(address safe => bool authorized)) public modules;

    event Initialized(address indexed safe);
    event Configured(address indexed safe, bytes32 configurationHash);
    event DelegateAuthorization(address indexed safe, address indexed delegate, bool authorized);
    event ModuleAuthorization(address indexed safe, address indexed module, bool authorized);
    event ConfigurationScheduled(address indexed safe, bytes32 configurationHash, uint256 timelock);
    event DisableScheduled(address indexed safe, uint256 timelock);

    error NotEnabled(address safe);
    error AlreadyInitialized(address safe);
    error NotInitialized(address safe);
    error UnauthorizedDelegateCall(address safe, address to);
    error UnauthorizedModule(address safe, address module);
    error UnauthorizedConfiguration(address safe, bytes32 configurationHash);
    error UnauthorizedDisable(address safe);

    function initialize(Configuration calldata configuration) external {
        if (!_isEnabled(msg.sender)) {
            revert NotEnabled(msg.sender);
        }

        Account storage account = accounts[msg.sender];
        if (accounts[msg.sender].initialized) {
            revert AlreadyInitialized(msg.sender);
        }

        account.initialized = true;
        account.configurationHash = bytes32(0);
        account.timelock = 0;

        _applyConfiguration(configuration);
        emit Initialized(msg.sender);
    }

    function configure(Configuration calldata configuration) external {
        bytes32 configurationHash = keccak256(abi.encode(configuration));

        Account storage account = accounts[msg.sender];
        if (account.configurationHash != configurationHash || account.timelock > block.timestamp) {
            revert UnauthorizedConfiguration(msg.sender, configurationHash);
        }

        account.configurationHash = bytes32(0);
        account.timelock = 0;

        _applyConfiguration(configuration);
        emit Configured(msg.sender, configurationHash);
    }

    function scheduleConfiguration(bytes32 configurationHash) external {
        Account storage account = accounts[msg.sender];
        if (!account.initialized) {
            revert NotInitialized(msg.sender);
        }

        uint256 timelock = block.timestamp + TIMELOCK;
        account.configurationHash = configurationHash;
        account.timelock = timelock;

        emit ConfigurationScheduled(msg.sender, configurationHash, timelock);
    }

    function scheduleDisabling() external {
        Account storage account = accounts[msg.sender];
        if (!account.initialized) {
            revert NotInitialized(msg.sender);
        }

        uint256 timelock = block.timestamp + TIMELOCK;
        account.configurationHash = DISABLE;
        account.timelock = timelock;

        emit DisableScheduled(msg.sender, timelock);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == type(IERC165).interfaceId || interfaceId == type(IModuleGuard).interfaceId
            || interfaceId == type(ITransactionGuard).interfaceId;
    }

    function checkModuleTransaction(address to, uint256, bytes calldata, uint8 operation, address module)
        external
        view
        returns (bytes32)
    {
        _checkTransaction(msg.sender, to, operation);
        if (!modules[msg.sender][module]) {
            revert UnauthorizedModule(msg.sender, module);
        }
        return bytes32(0);
    }

    function checkAfterModuleExecution(bytes32, bool) external {
        _checkAfterExecution(msg.sender);
    }

    function checkTransaction(
        address to,
        uint256,
        bytes calldata,
        uint8 operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes calldata,
        address
    ) external view {
        _checkTransaction(msg.sender, to, operation);
    }

    function checkAfterExecution(bytes32, bool) external {
        _checkAfterExecution(msg.sender);
    }

    function _applyConfiguration(Configuration calldata configuration) internal {
        for (uint256 i = 0; i < configuration.delegates.length; i++) {
            Authorization calldata delegate = configuration.delegates[i];
            delegates[msg.sender][delegate.addr] = delegate.authorized;
            emit DelegateAuthorization(msg.sender, delegate.addr, delegate.authorized);
        }
        for (uint256 i = 0; i < configuration.modules.length; i++) {
            Authorization calldata module = configuration.modules[i];
            modules[msg.sender][module.addr] = module.authorized;
            emit ModuleAuthorization(msg.sender, module.addr, module.authorized);
        }
    }

    function _isEnabled(address safe) internal view returns (bool enabled) {
        address moduleGuard = abi.decode(ISafe(safe).getStorageAt(MODULE_GUARD_STORAGE_SLOT, 1), (address));
        address transactionGuard = abi.decode(ISafe(safe).getStorageAt(TRANSACTION_GUARD_STORAGE_SLOT, 1), (address));
        enabled = moduleGuard == address(this) && transactionGuard == address(this);
    }

    function _checkTransaction(address safe, address to, uint8 operation) internal view {
        Account storage account = accounts[safe];
        if (account.initialized && operation == 1 && !delegates[safe][to]) {
            revert UnauthorizedDelegateCall(safe, to);
        }
    }

    function _checkAfterExecution(address safe) internal {
        if (!_isEnabled(safe)) {
            Account storage account = accounts[safe];
            if (account.initialized && account.configurationHash != DISABLE || account.timelock > block.timestamp) {
                revert UnauthorizedDisable(safe);
            }

            account.initialized = false;
            account.configurationHash = bytes32(0);
            account.timelock = 0;
        }
    }
}
