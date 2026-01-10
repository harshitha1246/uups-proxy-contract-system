// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVaultV1.sol";

contract TokenVaultV2 is TokenVaultV1 {
    uint256 internal _yieldRate;
    bool internal _depositsPaused;

    mapping(address => uint256) internal _lastYieldClaim;

    function setYieldRate(uint256 rate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _yieldRate = rate;
    }

    function getYieldRate() external view returns (uint256) {
        return _yieldRate;
    }

    function pauseDeposits() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _depositsPaused = true;
    }

    function unpauseDeposits() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _depositsPaused = false;
    }

    function isDepositsPaused() external view returns (bool) {
        return _depositsPaused;
    }

    function deposit(uint256 amount) public override {
        require(!_depositsPaused, "paused");

        if (_lastYieldClaim[msg.sender] == 0) {
            _lastYieldClaim[msg.sender] = block.timestamp;
        }

        super.deposit(amount);
    }

    function getUserYield(address user) public view returns (uint256) {
        if (_lastYieldClaim[user] == 0) return 0;

        return (_balances[user] * _yieldRate *
            (block.timestamp - _lastYieldClaim[user]))
            / (365 days * 10_000);
    }

    function claimYield() external {
        uint256 y = getUserYield(msg.sender);
        require(y > 0, "no yield");

        _lastYieldClaim[msg.sender] = block.timestamp;
        _balances[msg.sender] += y;
        _totalDeposits += y;
    }

    function getImplementationVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "V2";
    }

    uint256[47] private __gap;
}
