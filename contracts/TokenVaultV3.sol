// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVaultV2.sol";

contract TokenVaultV3 is TokenVaultV2 {
    struct WithdrawalRequest {
        uint256 amount;
        uint256 timestamp;
        bool executed;
    }

    uint256 private _withdrawalDelay;
    mapping(address => WithdrawalRequest) private _withdrawalRequests;

    event WithdrawalRequested(address indexed user, uint256 amount);
    event WithdrawalExecuted(address indexed user, uint256 amount);
    event EmergencyWithdrawal(address indexed user, uint256 amount);

    /* ---------------- ADMIN ---------------- */

    function setWithdrawalDelay(uint256 delay)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _withdrawalDelay = delay;
    }

    function getWithdrawalDelay() external view returns (uint256) {
        return _withdrawalDelay;
    }

    /* ---------------- USER ---------------- */

    function requestWithdrawal(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _withdrawalRequests[msg.sender] = WithdrawalRequest({
            amount: amount,
            timestamp: block.timestamp,
            executed: false
        });

        emit WithdrawalRequested(msg.sender, amount);
    }

    function executeWithdrawal() external {
        WithdrawalRequest storage req = _withdrawalRequests[msg.sender];

        require(req.amount > 0, "No withdrawal request");
        require(!req.executed, "Already executed");

        require(
            block.timestamp >= req.timestamp + _withdrawalDelay,
            "Withdrawal delay not met"
        );

        req.executed = true;

        _balances[msg.sender] -= req.amount;
        _totalDeposits -= req.amount;

        _token.transfer(msg.sender, req.amount);

        emit WithdrawalExecuted(msg.sender, req.amount);
    }

    function emergencyWithdraw() external {
        uint256 balance = _balances[msg.sender];
        require(balance > 0, "No balance");

        _balances[msg.sender] = 0;
        _totalDeposits -= balance;

        _token.transfer(msg.sender, balance);

        emit EmergencyWithdrawal(msg.sender, balance);
    }

    /* ---------------- TEST GETTERS ---------------- */

    function getWithdrawalRequest(address user)
        external
        view
        returns (WithdrawalRequest memory)
    {
        return _withdrawalRequests[user];
    }

    /* ---------------- STORAGE GAP ---------------- */

    uint256[47] private __gap;
}
