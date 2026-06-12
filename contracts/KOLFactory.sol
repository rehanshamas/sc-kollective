// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IKOLKeeper.sol";

/**
 * @title KOLFactory
 * @dev A simple upgradable contract with initializer and KOL whitelist
 * @custom:security-contact security@kollective.com
 */
contract KOLFactory is 
    Initializable, 
    UUPSUpgradeable, 
    OwnableUpgradeable 
{
    // Events
    event FactoryInitialized(address indexed owner);
    event UpgradeAuthorized(address indexed newImplementation);
    event KOLWhitelisted(address indexed kolAddress, bool isWhitelisted);
    event AdminAdded(address indexed adminAddress);
    event AdminRemoved(address indexed adminAddress);
    event KeeperCreated(address indexed keeperAddress, address indexed creator, string name);
    event StrategyWhitelisted(address indexed strategyAddress, bool isWhitelisted);
    event TokenAccepted(address indexed tokenAddress, bool isAccepted);
    event ProtocolWhitelisted(address indexed protocolAddress, bool isWhitelisted);
    event FundsManagerSet(address indexed fundsManager);

    // State variables
    string public name;
    uint256 public version;

    // KOL whitelist and admin management
    mapping(address => bool) public isKOLWhitelisted;
    mapping(address => bool) public isAdmin;

    // Strategy and token management
    mapping(address => bool) public tokensAccepted;
    address[] public whitelistedStrategies;
    mapping(address => uint256) public strategyIndex; // For O(1) removal

    // Protocol management
    mapping(address => bool) public protocolsWhitelisted;

    // Keeper management
    IKOLKeeper public keeperImplementation;
    address[] public deployedKeepers;

    // Funds manager
    address public fundsManager;

    // Modifiers
    modifier onlyKOL() {
        require(isKOLWhitelisted[msg.sender], "Caller is not a whitelisted KOL");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || msg.sender == owner(), "Caller is not an admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param initialOwner The initial owner of the contract
     * @param _name The name of the factory
     * @param _keeperImplementation The address of the keeper implementation
     */
    function initialize(
        address initialOwner, 
        string memory _name, 
        address _keeperImplementation
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        name = _name;
        version = 1;
        
        // Set the owner as the first admin
        isAdmin[initialOwner] = true;
        
        // Set the keeper implementation
        require(_keeperImplementation != address(0), "Invalid keeper implementation address");
        keeperImplementation = IKOLKeeper(_keeperImplementation);
        
        emit FactoryInitialized(initialOwner);
    }

    /**
     * @dev Sets the keeper implementation (only owner can call)
     * @param _keeperImplementation The address of the keeper implementation
     */
    function setKeeperImplementation(address _keeperImplementation) external onlyAdmin {
        require(_keeperImplementation != address(0), "Invalid keeper implementation address");
        keeperImplementation = IKOLKeeper(_keeperImplementation);
    }

    /**
     * @dev Sets the funds manager address (admin only)
     * @param _fundsManager The address of the funds manager contract
     */
    function setFundsManager(address _fundsManager) external onlyAdmin {
        require(_fundsManager != address(0), "Invalid funds manager address");
        fundsManager = _fundsManager;
        emit FundsManagerSet(_fundsManager);
    }

    /**
     * @dev Creates a new KOLKeeper proxy (only KOL can call)
     * @param keeperName The name for the keeper
     * @param acceptedTokens Array of accepted token addresses (1-3 tokens)
     * @return keeperAddress The address of the deployed keeper
     */
    function createKeeper(
        string memory keeperName, 
        address[] memory acceptedTokens
    ) external onlyKOL returns (address keeperAddress) {
        require(address(keeperImplementation) != address(0), "Keeper implementation not set");
        require(
            bytes(keeperName).length > 0 && bytes(keeperName).length <= 8, 
            "Keeper name length must be 1-8 characters"
        );
        require(acceptedTokens.length >= 1 && acceptedTokens.length <= 3, "Must accept 1-3 tokens");
        
        // Validate that all tokens are accepted in the factory
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            require(acceptedTokens[i] != address(0), "Invalid token address");
            require(tokensAccepted[acceptedTokens[i]], "Token not accepted in factory");
        }

        // Deploy proxy using Clones
        keeperAddress = Clones.clone(address(keeperImplementation));
        
        // Initialize the keeper with accepted tokens and funds manager
        IKOLKeeper(keeperAddress).initialize(
            owner(), 
            keeperName, 
            address(this), 
            acceptedTokens, 
            fundsManager, 
            msg.sender
        );
        
        // Add to deployed keepers list
        deployedKeepers.push(keeperAddress);
        
        emit KeeperCreated(keeperAddress, msg.sender, keeperName);
        
        return keeperAddress;
    }

    /**
     * @dev Adds or removes an admin (only owner can call)
     * @param adminAddress The address to add/remove as admin
     * @param isAdminStatus Whether to add or remove admin status
     */
    function setAdmin(address adminAddress, bool isAdminStatus) external onlyOwner {
        require(adminAddress != address(0), "Invalid admin address");
        require(adminAddress != owner(), "Cannot modify owner admin status");
        
        isAdmin[adminAddress] = isAdminStatus;
        
        if (isAdminStatus) {
            emit AdminAdded(adminAddress);
        } else {
            emit AdminRemoved(adminAddress);
        }
    }

    /**
     * @dev Whitelists or removes a KOL address (only admins can call)
     * @param kolAddress The address to whitelist/remove
     * @param isWhitelisted Whether to whitelist or remove
     */
    function setKOLWhitelist(address kolAddress, bool isWhitelisted) external onlyAdmin {
        require(kolAddress != address(0), "Invalid KOL address");
        isKOLWhitelisted[kolAddress] = isWhitelisted;
        emit KOLWhitelisted(kolAddress, isWhitelisted);
    }

    /**
     * @dev Whitelists or removes a strategy address (only admins can call)
     * @param strategyAddress The address to whitelist/remove
     * @param isWhitelisted Whether to whitelist or remove
     */
    function setStrategyWhitelist(address strategyAddress, bool isWhitelisted) external onlyAdmin {
        require(strategyAddress != address(0), "Invalid strategy address");
        
        bool wasWhitelisted = _isStrategyWhitelisted(strategyAddress);
        
        if (isWhitelisted && !wasWhitelisted) {
            strategyIndex[strategyAddress] = whitelistedStrategies.length;
            whitelistedStrategies.push(strategyAddress);
        } else if (!isWhitelisted && wasWhitelisted) {
            // Remove from array
            uint256 indexToRemove = strategyIndex[strategyAddress];
            if (indexToRemove < whitelistedStrategies.length - 1) {
                whitelistedStrategies[indexToRemove] = whitelistedStrategies[whitelistedStrategies.length - 1];
                strategyIndex[whitelistedStrategies[whitelistedStrategies.length - 1]] = indexToRemove;
            }
            whitelistedStrategies.pop();
            delete strategyIndex[strategyAddress];
        }
        
        emit StrategyWhitelisted(strategyAddress, isWhitelisted);
    }

    /**
     * @dev Whitelists or removes a token address (only admins can call)
     * @param tokenAddress The address to whitelist/remove
     * @param isAccepted Whether to accept or remove
     */
    function setTokenAccepted(address tokenAddress, bool isAccepted) external onlyAdmin {
        require(tokenAddress != address(0), "Invalid token address");
        tokensAccepted[tokenAddress] = isAccepted;
        emit TokenAccepted(tokenAddress, isAccepted);
    }

    /**
     * @dev Whitelists or removes a protocol address (only admins can call)
     * @param protocolAddress The address to whitelist/remove
     * @param isWhitelisted Whether to whitelist or remove
     */
    function setProtocolWhitelist(address protocolAddress, bool isWhitelisted) external onlyAdmin {
        require(protocolAddress != address(0), "Invalid protocol address");
        protocolsWhitelisted[protocolAddress] = isWhitelisted;
        emit ProtocolWhitelisted(protocolAddress, isWhitelisted);
    }

    /**
     * @dev Check if an address is whitelisted as KOL
     * @param kolAddress The address to check
     * @return True if whitelisted
     */
    function isWhitelistedKOL(address kolAddress) external view returns (bool) {
        return isKOLWhitelisted[kolAddress];
    }

    /**
     * @dev Internal function to check if a strategy address is whitelisted
     * @param strategyAddress The address to check
     * @return True if whitelisted
     */
    function _isStrategyWhitelisted(address strategyAddress) internal view returns (bool) {
        uint256 index = strategyIndex[strategyAddress];
        return index < whitelistedStrategies.length && whitelistedStrategies[index] == strategyAddress;
    }

    /**
     * @dev Internal function to check if a protocol address is whitelisted
     * @param protocolAddress The address to check
     * @return True if whitelisted
     */
    function _isProtocolWhitelisted(address protocolAddress) internal view returns (bool) {
        return protocolsWhitelisted[protocolAddress];
    }

    /**
     * @dev Check if a strategy address is whitelisted
     * @param strategyAddress The address to check
     * @return True if whitelisted
     */
    function isStrategyWhitelisted(address strategyAddress) external view returns (bool) {
        return _isStrategyWhitelisted(strategyAddress);
    }

    /**
     * @dev Check if a protocol address is whitelisted
     * @param protocolAddress The address to check
     * @return True if whitelisted
     */
    function isProtocolWhitelisted(address protocolAddress) external view returns (bool) {
        return _isProtocolWhitelisted(protocolAddress);
    }

    /**
     * @dev Check if a token address is accepted
     * @param tokenAddress The address to check
     * @return True if accepted
     */
    function isTokenAccepted(address tokenAddress) external view returns (bool) {
        return tokensAccepted[tokenAddress];
    }

    /**
     * @dev Check if an address is an admin
     * @param adminAddress The address to check
     * @return True if admin
     */
    function checkIsAdmin(address adminAddress) external view returns (bool) {
        return isAdmin[adminAddress] || adminAddress == owner();
    }

    /**
     * @dev Get all deployed keepers
     * @return Array of deployed keeper addresses
     */
    function getDeployedKeepers() external view returns (address[] memory) {
        return deployedKeepers;
    }

    /**
     * @dev Get the number of deployed keepers
     * @return Number of deployed keepers
     */
    function getDeployedKeepersCount() external view returns (uint256) {
        return deployedKeepers.length;
    }

    /**
     * @dev Get keeper at specific index
     * @param index The index of the keeper
     * @return The keeper address at the specified index
     */
    function getKeeperAtIndex(uint256 index) external view returns (address) {
        require(index < deployedKeepers.length, "Index out of bounds");
        return deployedKeepers[index];
    }

    /**
     * @dev Get all whitelisted strategies
     * @return Array of all whitelisted strategy addresses
     */
    function getAllWhitelistedStrategies() external view returns (address[] memory) {
        return whitelistedStrategies;
    }

    /**
     * @dev Get the number of whitelisted strategies
     * @return Number of whitelisted strategies
     */
    function getWhitelistedStrategiesCount() external view returns (uint256) {
        return whitelistedStrategies.length;
    }

    /**
     * @dev Get whitelisted strategy at specific index
     * @param index The index of the strategy
     * @return The strategy address at the specified index
     */
    function getWhitelistedStrategyAtIndex(uint256 index) external view returns (address) {
        require(index < whitelistedStrategies.length, "Index out of bounds");
        return whitelistedStrategies[index];
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
} 