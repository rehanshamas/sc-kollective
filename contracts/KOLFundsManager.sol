// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IKOLKeeper.sol";
import "./interfaces/IKOLFactory.sol";

/**
 * @title KOLFundsManager
 * @dev An upgradable contract for managing KOL funds
 * @custom:security-contact security@kollective.com
 */
contract KOLFundsManager is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable 
{
    using SafeERC20 for IERC20;

    // Events
    event FundsManagerInitialized(address indexed owner);
    event UpgradeAuthorized(address indexed newImplementation);
    event TokensReceived(address indexed token, address indexed from, uint256 amount);
    event FundMeCalled(address indexed token, address indexed from, uint256 amount);
    event PoolCreated(address indexed keeper, address indexed token);
    event PoolUpdated(address indexed keeper, address indexed token, uint256 newTotal);
    event FundsSeeded(address indexed keeper, address indexed token, address[] strategies, uint256[] amounts);
    event EmergencyWithdrawal(address indexed keeper, address indexed token, address indexed user, uint256 amount);

    // State variables
    string public name;
    uint256 public version;

    // Reference to KOLKeeper for tracking deposits
    address public kolKeeper;

    // Reference to KOLFactory for role checking
    IKOLFactory public kolFactory;

    // Pool management: keeper => token => total funds
    mapping(address => mapping(address => uint256)) public kollectiveFunds; // Total funds deposited by users
    mapping(address => mapping(address => uint256)) public investedFunds; // Total funds invested via seedFunds

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param initialOwner The initial owner of the contract
     * @param _name The name of the funds manager
     * @param _kolFactory The address of the KOLFactory contract
     */
    function initialize(
        address initialOwner,
        string memory _name,
        address _kolFactory
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        name = _name;
        version = 1;
        
        // Set KOLFactory reference
        require(_kolFactory != address(0), "Invalid KOLFactory address");
        kolFactory = IKOLFactory(_kolFactory);
        
        emit FundsManagerInitialized(initialOwner);
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
     * @dev Function to receive ETH when msg.data is empty
     */
    receive() external payable {
        // Contract can receive ETH
    }

    /**
     * @dev Fallback function to receive ETH when msg.data is not empty
     */
    fallback() external payable {
        // Contract can receive ETH
    }

    /**
     * @dev Function to receive ERC20 tokens
     * This allows the contract to receive ERC20 tokens via transfer
     */
    function onERC20Received(
        address token,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        emit TokensReceived(token, from, amount);
        return this.onERC20Received.selector;
    }

    /**
     * @dev Function called by users to deposit funds directly
     * @param token The ERC20 token address
     * @param amount The amount to deposit
     * @param keeperAddress The address of the KOLKeeper to track the deposit
     */
    function depositFunds(address token, uint256 amount, address keeperAddress) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token != address(0), "Invalid token address");
        require(keeperAddress != address(0), "Invalid keeper address");
        
        // Transfer tokens directly from user to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Update pool
        _updatePool(keeperAddress, token, amount);
        
        // Call KOLKeeper to track the deposit using interface
        IKOLKeeper(keeperAddress).trackDeposit(token, amount, msg.sender);
        
        emit FundMeCalled(token, msg.sender, amount);
    }

    /**
     * @dev Set the KOLFactory address (only admin can call)
     * @param _kolFactory The address of the KOLFactory contract
     */
    function setKOLFactory(address _kolFactory) external onlyAdmin {
        require(_kolFactory != address(0), "Invalid factory address");
        kolFactory = IKOLFactory(_kolFactory);
    }

    /**
     * @dev Internal function to check if caller is the creator of a keeper
     * @param keeper The keeper address to check
     * @param caller The address to check
     * @return True if caller is the creator
     */
    function _isKeeperCreator(address keeper, address caller) internal view returns (bool) {
        return IKOLKeeper(keeper).creator() == caller;
    }

    /**
     * @dev Seed funds from keeper's pool into whitelisted strategies
     * @param keeper The keeper address to invest from
     * @param token The token address to invest
     * @param strategies Array of strategy addresses to invest in
     * @param amounts Array of amounts (18 decimals) for each strategy
     */
    function seedFunds(
        address keeper,
        address token,
        address[] memory strategies,
        uint256[] memory amounts
    ) external onlyKOL {
        require(strategies.length > 0, "Strategies array cannot be empty");
        require(strategies.length == amounts.length, "Arrays length mismatch");
        require(strategies.length <= 10, "Too many strategies"); // Reasonable limit
        
        // Check if keeper's pool exists and has funds
        uint256 kollectiveAmount = kollectiveFunds[keeper][token];
        uint256 investedAmount = investedFunds[keeper][token];
        uint256 availableAmount = kollectiveAmount - investedAmount;
        require(availableAmount > 0, "No available funds in pool");
        
        // Check if caller is the creator of the keeper
        require(_isKeeperCreator(keeper, msg.sender), "Caller is not the keeper creator");
        
        // Validate amounts and check strategy whitelist
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than 0");
            
            // Check if strategy is whitelisted
            require(
                kolFactory.isStrategyWhitelisted(strategies[i]),
                "Strategy not whitelisted"
            );
            
            totalAmount += amounts[i];
        }
        
        // Ensure total amount doesn't exceed available pool amount
        require(totalAmount <= availableAmount, "Total amount cannot exceed available pool amount");
        
        // Update invested funds
        investedFunds[keeper][token] += totalAmount;
        
        emit FundsSeeded(keeper, token, strategies, amounts);
    }

    /**
     * @dev Emergency withdrawal function for users to withdraw their deposited funds
     * @param keeper The keeper address to withdraw from
     * @param token The token address to withdraw
     * @param amount The amount to withdraw
     */
    function emergencyWithdraw(
        address keeper,
        address token,
        uint256 amount
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        require(keeper != address(0), "Invalid keeper address");
        require(token != address(0), "Invalid token address");
        
        // Check if keeper has available funds
        uint256 availableFunds = kollectiveFunds[keeper][token] - investedFunds[keeper][token];
        require(availableFunds >= amount, "Insufficient available funds in vault");
        
        // Check if user has sufficient deposits
        uint256 userDeposits = IKOLKeeper(keeper).getUserTokenDeposit(msg.sender, token);
        require(userDeposits >= amount, "Insufficient deposits");
        
        // Transfer tokens to user
        IERC20(token).safeTransfer(msg.sender, amount);
        
        // Update kollective funds (reduce the deposited amount)
        kollectiveFunds[keeper][token] -= amount;
        
        // Update KOLKeeper tracking
        IKOLKeeper(keeper).trackWithdrawal(token, amount, msg.sender);
        
        emit EmergencyWithdrawal(keeper, token, msg.sender, amount);
    }

    /**
     * @dev Internal function to update pool for a keeper-token pair
     * @param keeper The keeper address
     * @param token The token address
     * @param amount The amount to add to the pool
     */
    function _updatePool(address keeper, address token, uint256 amount) internal {
        uint256 currentAmount = kollectiveFunds[keeper][token];
        
        if (currentAmount == 0) {
            // Create new pool
            kollectiveFunds[keeper][token] = amount;
            emit PoolCreated(keeper, token);
        } else {
            // Update existing pool
            kollectiveFunds[keeper][token] = currentAmount + amount;
        }
        
        emit PoolUpdated(keeper, token, kollectiveFunds[keeper][token]);
    }

    /**
     * @dev Get pool amount for a keeper-token pair
     * @param keeper The keeper address
     * @param token The token address
     * @return amount The total amount in the pool
     */
    function getPoolAmount(address keeper, address token) external view returns (uint256 amount) {
        return kollectiveFunds[keeper][token];
    }

    /**
     * @dev Get total funds for a keeper across all tokens
     * @param keeper The keeper address
     * @param acceptedTokens Array of accepted tokens for the keeper
     * @return total Total funds across all accepted tokens
     */
    function getKeeperTotalFunds(
        address keeper, 
        address[] memory acceptedTokens
    ) external view returns (uint256 total) {
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            total += kollectiveFunds[keeper][acceptedTokens[i]];
        }
        return total;
    }

    /**
     * @dev Get total funds for a token across all keepers
     * @param token The token address
     * @param keepers Array of keeper addresses to check
     * @return total Total funds across specified keepers
     */
    function getTokenTotalFunds(address token, address[] memory keepers) external view returns (uint256 total) {
        for (uint256 i = 0; i < keepers.length; i++) {
            total += kollectiveFunds[keepers[i]][token];
        }
        return total;
    }

    /**
     * @dev Set the KOLKeeper address for tracking deposits
     * @param _kolKeeper The implementation address of the KOLKeeper contract
     */
    function setKOLKeeper(address _kolKeeper) external onlyOwner {
        require(_kolKeeper != address(0), "Invalid keeper address");
        kolKeeper = _kolKeeper;
    }

    /**
     * @dev Get available funds for a keeper-token pair (deposited - invested)
     * @param keeper The keeper address
     * @param token The token address
     * @return available The available amount for investment
     */
    function getAvailableFunds(address keeper, address token) external view returns (uint256 available) {
        return kollectiveFunds[keeper][token] - investedFunds[keeper][token];
    }

    /**
     * @dev Get invested funds for a keeper-token pair
     * @param keeper The keeper address
     * @param token The token address
     * @return invested The total invested amount
     */
    function getInvestedFunds(address keeper, address token) external view returns (uint256 invested) {
        return investedFunds[keeper][token];
    }
} 