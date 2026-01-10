// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVaultV1 is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IERC20 internal _token;
    uint256 internal _depositFee;

    mapping(address => uint256) internal _balances;
    uint256 internal _totalDeposits;

    event Deposited(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address token_,
        address admin_,
        uint256 depositFee_
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _token = IERC20(token_);
        _depositFee = depositFee_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
    }

    function deposit(uint256 amount) public virtual {
        require(amount > 0, "amount=0");

        uint256 fee = (amount * _depositFee) / 10_000;
        uint256 credited = amount - fee;

        _token.transferFrom(msg.sender, address(this), amount);

        _balances[msg.sender] += credited;
        _totalDeposits += credited;

        emit Deposited(msg.sender, credited, fee);
    }

    function withdraw(uint256 amount) public virtual {
        require(_balances[msg.sender] >= amount, "insufficient");

        _balances[msg.sender] -= amount;
        _totalDeposits -= amount;

        _token.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    function totalDeposits() external view returns (uint256) {
        return _totalDeposits;
    }

    function getImplementationVersion()
        external
        pure
        virtual
        returns (string memory)
    {
        return "V1";
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    uint256[50] private __gap;
}
