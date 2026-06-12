// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../KOLStrategyBase.sol";

/**
 * @title DhedgeStrategy
 * @dev Strategy contract for dhedge protocol integration
 * @custom:security-contact security@kollective.com
 */
contract DhedgeStrategy is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    KOLStrategyBase 
{
    using SafeERC20 for IERC20;

    // Events
    event DhedgeStrategyInitialized(address indexed owner, address indexed fundsManager);
    event StrategyInvested(address indexed token, uint256 amount);
    event StrategyHarvested(address indexed token, uint256 amount);
    event StrategyWithdrawnAll(address indexed token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the dhedge strategy
     * @param initialOwner The initial owner of the strategy
     * @param _name The name of the strategy
     * @param _fundsManager The funds manager address
     */
    function initialize(
        address initialOwner,
        string memory _name,
        address _fundsManager
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        name = _name;
        
        // Call super initializer
        super.initialize(_fundsManager);
        
        emit DhedgeStrategyInitialized(initialOwner, _fundsManager);
    }

    /**
     * @dev Required by the OZ UUPS module
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Upgrade logic will be added later
    }

    /**
     * @dev Set the funds manager address (only owner)
     * @param _fundsManager The funds manager address
     */
    function setFundsManager(address _fundsManager) external onlyOwner {
        require(_fundsManager != address(0), "Invalid funds manager address");
        fundsManager = _fundsManager;
    }

    /**
     * @dev Invest funds into the strategy (only funds manager)
     * @param token The token address to invest
     * @param amount The amount to invest
     */
    function invest(address token, uint256 amount) external override onlyFundsManager {
        // Implementation will be added later
        emit StrategyInvested(token, amount);
    }

    /**
     * @dev Harvest rewards from the strategy (only funds manager)
     * @param token The token address to harvest
     */
    function harvest(address token) external override onlyFundsManager {
        // Implementation will be added later
        emit StrategyHarvested(token, 0);
    }

    /**
     * @dev Withdraw all funds from the strategy (only funds manager)
     * @param token The token address to withdraw
     */
    function withdrawAll(address token) external override onlyFundsManager {
        // Implementation will be added later
        emit StrategyWithdrawnAll(token, 0);
    }

    /**
     * @dev Emergency function to recover stuck tokens (only owner)
     * @param token The token address to recover
     * @param amount The amount to recover
     * @param recipient The recipient address
     */
    function emergencyRecover(address token, uint256 amount, address recipient) external override onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransfer(recipient, amount);
    }
} 