// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IKOLFactory.sol";

/**
 * @title KOLKeeper
 * @dev An upgradable contract that inherits modifiers and roles from KOLFactory
 * @custom:security-contact security@kollective.com
 */
contract KOLKeeper is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable 
{
    using SafeERC20 for IERC20;

    // Events
    event KeeperInitialized(address indexed owner);
    event UpgradeAuthorized(address indexed newImplementation);
    event FundsDeposited(address indexed user, address indexed token, uint256 amount, uint256 percentage);
    event FundsWithdrawn(address indexed user, address indexed token, uint256 amount, uint256 percentage);

    // State variables
    string public name;
    uint256 public version;

    // Reference to KOLFactory for role checking
    IKOLFactory public kolFactory;

    // Reference to KOLFundsManager for fund transfers
    address public fundsManager;

    // Keeper creator (the KOL who created this keeper)
    address public creator;

    // Accepted tokens for this keeper (immutable after initialization)
    address[] public acceptedTokens;

    // User deposit tracking
    mapping(address => mapping(address => uint256)) public userTokenDeposits; // user => token => amount
    mapping(address => uint256) public totalTokenDeposits; // token => total amount

    // Modifiers inherited from KOLFactory
    modifier onlyKOL() {
        require(kolFactory.isWhitelistedKOL(msg.sender), "Caller is not a whitelisted KOL");
        _;
    }

    modifier onlyAdmin() {
        require(kolFactory.checkIsAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyFactoryOwner() {
        require(msg.sender == kolFactory.owner(), "Caller is not the owner");
        _;
    }

    modifier onlyFundsManager() {
        require(msg.sender == fundsManager, "Caller is not the funds manager");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param initialOwner The initial owner of the contract
     * @param _name The name of the keeper
     * @param _kolFactory The address of the KOLFactory contract
     * @param _acceptedTokens Array of accepted token addresses for this keeper
     * @param _fundsManager The address of the KOLFundsManager contract
     * @param _creator The address of the KOL who created this keeper
     */
    function initialize(
        address initialOwner,
        string memory _name, 
        address _kolFactory,
        address[] memory _acceptedTokens,
        address _fundsManager,
        address _creator
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        name = _name;
        version = 1;
        kolFactory = IKOLFactory(_kolFactory);
        fundsManager = _fundsManager;
        creator = _creator;
        
        // Set accepted tokens for this keeper
        require(_acceptedTokens.length >= 1 && _acceptedTokens.length <= 3, "Must accept 1-3 tokens");
        acceptedTokens = _acceptedTokens;
        
        emit KeeperInitialized(initialOwner);
    }

    /**
     * @dev Required by the OZ UUPS module
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        emit UpgradeAuthorized(newImplementation);
    }

    /**
     * @dev Returns the current version of the contract
     */
    function getVersion() external view returns (uint256) {
        return version;
    }

    /**
     * @dev Get the KOLFactory address
     */
    function getKOLFactory() external view returns (address) {
        return address(kolFactory);
    }

    /**
     * @dev Get the number of accepted tokens
     * @return Number of accepted tokens
     */
    function getAcceptedTokensCount() external view returns (uint256) {
        return acceptedTokens.length;
    }

    /**
     * @dev Get accepted token at specific index
     * @param index The index of the token
     * @return The token address at the specified index
     */
    function getAcceptedTokenAtIndex(uint256 index) external view returns (address) {
        require(index < acceptedTokens.length, "Index out of bounds");
        return acceptedTokens[index];
    }

    /**
     * @dev Get all accepted tokens
     * @return Array of all accepted token addresses
     */
    function getAllAcceptedTokens() external view returns (address[] memory) {
        return acceptedTokens;
    }

    /**
     * @dev Internal function to check if a token is accepted by this keeper
     * @param tokenAddress The address to check
     * @return True if accepted
     */
    function _isTokenAccepted(address tokenAddress) internal view returns (bool) {
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            if (acceptedTokens[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Track deposit called by KOLFundsManager after successful fund transfer
     * @param token The ERC20 token address that was deposited
     * @param amount The amount that was deposited
     * @param user The address of the user who deposited
     */
    function trackDeposit(address token, uint256 amount, address user) external onlyFundsManager {
        require(amount > 0, "Amount must be greater than 0");
        require(_isTokenAccepted(token), "Token not accepted");
        require(user != address(0), "Invalid user address");
        
        // Update user deposit tracking
        userTokenDeposits[user][token] += amount;
        
        // Update total deposits for this token
        totalTokenDeposits[token] += amount;
        
        emit FundsDeposited(user, token, amount, 0);
    }

    /**
     * @dev Track withdrawal called by KOLFundsManager after successful fund withdrawal
     * @param token The ERC20 token address that was withdrawn
     * @param amount The amount that was withdrawn
     * @param user The address of the user who withdrew
     */
    function trackWithdrawal(address token, uint256 amount, address user) external onlyFundsManager {
        require(amount > 0, "Amount must be greater than 0");
        require(_isTokenAccepted(token), "Token not accepted");
        require(user != address(0), "Invalid user address");
        require(userTokenDeposits[user][token] >= amount, "Insufficient user deposits");
        
        // Update user deposit tracking
        userTokenDeposits[user][token] -= amount;
        
        // Update total deposits for this token
        totalTokenDeposits[token] -= amount;
        
        emit FundsWithdrawn(user, token, amount, 0);
    }

    /**
     * @dev Get user's percentage for a specific token
     * @param user The user address
     * @param token The token address
     * @return percentage The user's percentage (0-1 scale)
     */
    function getUserTokenPercentage(address user, address token) external view returns (uint256 percentage) {
        uint256 total = totalTokenDeposits[token];
        if (total == 0) return 0;
        
        return (userTokenDeposits[user][token] * 1e18) / total; // Returns percentage with 18 decimals
    }

    /**
     * @dev Get user's deposit amount for a specific token
     * @param user The user address
     * @param token The token address
     * @return amount The user's deposit amount
     */
    function getUserTokenDeposit(address user, address token) external view returns (uint256 amount) {
        return userTokenDeposits[user][token];
    }

    /**
     * @dev Get total deposits for a specific token
     * @param token The token address
     * @return total The total deposits for this token
     */
    function getTotalTokenDeposits(address token) external view returns (uint256 total) {
        return totalTokenDeposits[token];
    }

    /**
     * @dev Check if a token is accepted by this keeper
     * @param tokenAddress The address to check
     * @return True if accepted
     */
    function isTokenAccepted(address tokenAddress) external view returns (bool) {
        return _isTokenAccepted(tokenAddress);
    }

    /**
     * @dev Get the KOLFundsManager address for direct transfers
     */
    function getFundsManager() external view returns (address) {
        return fundsManager;
    }
} 