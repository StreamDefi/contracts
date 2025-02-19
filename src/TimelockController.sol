// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TimelockController is Ownable, ReentrancyGuard {
    uint256 public minDelay;
    uint256 public queuedDelay;
    uint256 public delayChangeScheduledAt;
    
    // Hardcoded function selectors that can bypass timelock
    bytes4 public constant ROLL_TO_NEXT_ROUND = bytes4(keccak256("rollToNextRound(uint256,bool)"));
    bytes4 public constant PROCESS_WITHDRAWALS = bytes4(keccak256("processWithdrawals()"));
    
    mapping(bytes32 => uint256) public timestamps;
    
    event OperationScheduled(
        bytes32 indexed id,
        address indexed target,
        bytes data,
        bytes32 salt,
        uint256 timestamp
    );
    event OperationExecuted(
        bytes32 indexed id,
        address indexed target,
        bytes data,
        bytes32 salt
    );
    event ImmediateOperationExecuted(
        address indexed target,
        bytes data,
        bytes4 indexed selector
    );
    event OperationFailed(
        bytes32 indexed id,
        address indexed target,
        bytes data,
        bytes32 salt
    );
    event DelayChangeQueued(uint256 oldDelay, uint256 newDelay, uint256 effectiveAt);
    event DelayUpdated(uint256 oldDelay, uint256 newDelay);
    
    error DelayMustBeGreaterThanZero();
    error NoDelayChangeQueued();
    error DelayChangeNotReady();
    error OperationNotFound();
    error OperationNotReady();
    error OperationAlreadyScheduled();
    error FunctionMustBeImmediate();
    error OperationFail();
    
    constructor(
        address initialOwner,
        uint256 initialDelay
    ) Ownable(initialOwner) {
        if (initialDelay == 0) revert DelayMustBeGreaterThanZero();
        minDelay = initialDelay;
    }
    
    function executeImmediate(
        address target,
        bytes calldata data
    ) external onlyOwner nonReentrant {
        bytes4 selector = bytes4(data[:4]);
        if (selector != ROLL_TO_NEXT_ROUND && selector != PROCESS_WITHDRAWALS) {
            revert FunctionMustBeImmediate();
        }
        
        (bool success, ) = target.call(data);
        if (!success) revert OperationFail();
        
        emit ImmediateOperationExecuted(target, data, selector);
    }
    
    function executeDelayed(
        address target,
        bytes calldata data,
        bytes32 salt
    ) external onlyOwner nonReentrant {
        bytes32 id = keccak256(abi.encode(target, data, salt));
        if (timestamps[id] == 0) revert OperationNotFound();
        if (block.timestamp < timestamps[id]) revert OperationNotReady();
        
        delete timestamps[id];
        
        (bool success, ) = target.call(data);
        if (success) {
            emit OperationExecuted(id, target, data, salt);
        } else {
            emit OperationFailed(id, target, data, salt);
            revert OperationFail();
        }
    }
    
    function schedule(
        address target,
        bytes calldata data,
        bytes32 salt
    ) external onlyOwner {
        bytes32 id = keccak256(abi.encode(target, data, salt));
        if (timestamps[id] != 0) revert OperationAlreadyScheduled();
        
        timestamps[id] = block.timestamp + minDelay;
        
        emit OperationScheduled(id, target, data, salt, timestamps[id]);
    }
    
    function queueNewDelay(uint256 newDelay) external onlyOwner {
        if (newDelay == 0) revert DelayMustBeGreaterThanZero();
        
        queuedDelay = newDelay;
        delayChangeScheduledAt = block.timestamp + minDelay;
        
        emit DelayChangeQueued(minDelay, newDelay, delayChangeScheduledAt);
    }
    
    function updateDelay() external onlyOwner {
        if (delayChangeScheduledAt == 0) revert NoDelayChangeQueued();
        if (block.timestamp < delayChangeScheduledAt) revert DelayChangeNotReady();
        
        uint256 oldDelay = minDelay;
        minDelay = queuedDelay;
        
        delete queuedDelay;
        delete delayChangeScheduledAt;
        
        emit DelayUpdated(oldDelay, minDelay);
    }
    
    function isOperationPending(bytes32 id) external view returns (bool) {
        return timestamps[id] != 0 && timestamps[id] > block.timestamp;
    }
    
    function isOperationReady(bytes32 id) external view returns (bool) {
        return timestamps[id] != 0 && timestamps[id] <= block.timestamp;
    }
} 