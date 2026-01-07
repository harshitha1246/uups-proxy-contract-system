// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVaultV1.sol";

contract TokenVaultV2 is TokenVaultV1 {
    uint256 public yieldRate;
    bool public depositsPaused;
    
    mapping(address => uint256) public lastYieldClaimTime;
    mapping(address => uint256) public accumulatedYield;
    
    uint256[44] private __gap;

    event YieldRateUpdated(uint256 newRate);
    event YieldClaimed(address indexed user, uint256 amount);
    event DepositsStatusChanged(bool isPaused);

    function setYieldRate(uint256 _yieldRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_yieldRate <= 10000, "Yield rate too high");
        yieldRate = _yieldRate;
        emit YieldRateUpdated(_yieldRate);
    }

    function getYieldRate() external view returns (uint256) {
        return yieldRate;
    }

    function pauseDeposits() external onlyRole(DEFAULT_ADMIN_ROLE) {
        depositsPaused = true;
        emit DepositsStatusChanged(true);
    }

    function unpauseDeposits() external onlyRole(DEFAULT_ADMIN_ROLE) {
        depositsPaused = false;
        emit DepositsStatusChanged(false);
    }

    function isDepositsPaused() external view returns (bool) {
        return depositsPaused;
    }

    function deposit(uint256 amount) external override {
        require(!depositsPaused, "Deposits are paused");
        super.deposit(amount);
        lastYieldClaimTime[msg.sender] = block.timestamp;
    }

    function getUserYield(address user) external view returns (uint256) {
        if(userBalances[user] == 0 || yieldRate == 0) return accumulatedYield[user];
        uint256 timeElapsed = block.timestamp - lastYieldClaimTime[user];
        uint256 yield = (userBalances[user] * yieldRate * timeElapsed) / (365 days * 10000);
        return accumulatedYield[user] + yield;
    }

    function claimYield() external returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastYieldClaimTime[msg.sender];
        uint256 yield = (userBalances[msg.sender] * yieldRate * timeElapsed) / (365 days * 10000);
        uint256 totalYield = accumulatedYield[msg.sender] + yield;
        require(totalYield > 0, "No yield to claim");
        accumulatedYield[msg.sender] = 0;
        lastYieldClaimTime[msg.sender] = block.timestamp;
        token.transfer(msg.sender, totalYield);
        emit YieldClaimed(msg.sender, totalYield);
        return totalYield;
    }

    function getImplementationVersion() external pure override returns (string memory) {
        return "V2";
    }
}
