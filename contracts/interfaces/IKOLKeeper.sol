// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IKOLKeeper
 * @dev Interface for KOLKeeper contract
 */
interface IKOLKeeper {
    /**
     * @dev Initialize the keeper contract
     * @param initialOwner The initial owner of the contract
     * @param _name The name of the keeper
     * @param _kolFactory The address of the KOLFactory contract
     * @param _acceptedTokens Array of accepted token addresses
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
    ) external;

    /**
     * @dev Track a deposit made by a user
     * @param token The token address
     * @param amount The amount deposited
     * @param user The user address
     */
    function trackDeposit(address token, uint256 amount, address user) external;

    /**
     * @dev Track a withdrawal made by a user
     * @param token The token address
     * @param amount The amount withdrawn
     * @param user The user address
     */
    function trackWithdrawal(address token, uint256 amount, address user) external;

    /**
     * @dev Get the funds manager address
     * @return The funds manager address
     */
    function getFundsManager() external view returns (address);

    /**
     * @dev Get user's percentage for a specific token
     * @param user The user address
     * @param token The token address
     * @return percentage The user's percentage (0-1 scale)
     */
    function getUserTokenPercentage(address user, address token) external view returns (uint256 percentage);

    /**
     * @dev Get user's deposit amount for a specific token
     * @param user The user address
     * @param token The token address
     * @return amount The user's deposit amount
     */
    function getUserTokenDeposit(address user, address token) external view returns (uint256 amount);

    /**
     * @dev Get total deposits for a specific token
     * @param token The token address
     * @return total The total deposits for this token
     */
    function getTotalTokenDeposits(address token) external view returns (uint256 total);

    /**
     * @dev Check if a token is accepted by this keeper
     * @param tokenAddress The address to check
     * @return True if accepted
     */
    function isTokenAccepted(address tokenAddress) external view returns (bool);

    /**
     * @dev Get the creator of this keeper
     * @return The address of the KOL who created this keeper
     */
    function creator() external view returns (address);
} 