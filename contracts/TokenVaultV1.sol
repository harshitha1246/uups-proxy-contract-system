// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVaultV1 is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    
    IERC20 public token;
    address public admin;
    uint256 public depositFee;
    
    mapping(address => uint256) public userBalances;
    uint256 public totalDeposits;
    
    uint256[47] private __gap;

    event Deposit(address indexed user, uint256 amount, uint256 fee);
    event Withdraw(address indexed user, uint256 amount);
    event FeeUpdated(uint256 newFee);

    function initialize(
        address _token,
        address _admin,
        uint256 _depositFee
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        token = IERC20(_token);
        admin = _admin;
        depositFee = _depositFee;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 fee = (amount * depositFee) / 10000;
        uint256 depositAmount = amount - fee;
        
        token.transferFrom(msg.sender, address(this), amount);
        
        userBalances[msg.sender] += depositAmount;
        totalDeposits += depositAmount;
        
        emit Deposit(msg.sender, amount, fee);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        
        userBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        token.transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return userBalances[user];
    }

    function totalDepositsAmount() external view returns (uint256) {
        return totalDeposits;
    }

    function getDepositFee() external view returns (uint256) {
        return depositFee;
    }

    function getImplementationVersion() external pure returns (string memory) {
        return "V1";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
