// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVaultV2.sol";

struct WithdrawalRequest {
    uint256 amount;
    uint256 requestTime;
}

contract TokenVaultV3 is TokenVaultV2 {
    uint256 public withdrawalDelay;
    
    mapping(address => WithdrawalRequest) public pendingWithdrawals;
    
    uint256[45] private __gap;

    event WithdrawalRequested(address indexed user, uint256 amount, uint256 requestTime);
    event WithdrawalExecuted(address indexed user, uint256 amount);
    event WithdrawalDelayUpdated(uint256 newDelay);
    event EmergencyWithdrawn(address indexed user, uint256 amount);

    function setWithdrawalDelay(uint256 _delaySeconds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawalDelay = _delaySeconds;
        emit WithdrawalDelayUpdated(_delaySeconds);
    }

    function getWithdrawalDelay() external view returns (uint256) {
        return withdrawalDelay;
    }

    function requestWithdrawal(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        pendingWithdrawals[msg.sender] = WithdrawalRequest(amount, block.timestamp);
        emit WithdrawalRequested(msg.sender, amount, block.timestamp);
    }

    function executeWithdrawal() external returns (uint256) {
        WithdrawalRequest memory request = pendingWithdrawals[msg.sender];
        require(request.amount > 0, "No pending withdrawal");
        require(block.timestamp >= request.requestTime + withdrawalDelay, "Withdrawal delay not met");
        
        uint256 amount = request.amount;
        userBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        delete pendingWithdrawals[msg.sender];
        
        token.transfer(msg.sender, amount);
        emit WithdrawalExecuted(msg.sender, amount);
        return amount;
    }

    function getWithdrawalRequest(address user) external view returns (uint256 amount, uint256 requestTime) {
        WithdrawalRequest memory request = pendingWithdrawals[user];
        return (request.amount, request.requestTime);
    }

    function emergencyWithdraw() external returns (uint256) {
        uint256 amount = userBalances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        userBalances[msg.sender] = 0;
        totalDeposits -= amount;
        delete pendingWithdrawals[msg.sender];
        
        token.transfer(msg.sender, amount);
        emit EmergencyWithdrawn(msg.sender, amount);
        return amount;
    }

    function getImplementationVersion() external pure override returns (string memory) {
        return "V3";
    }
}
