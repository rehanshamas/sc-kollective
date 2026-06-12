// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IKOLFactory
 * @dev Interface for KOLFactory contract
 */
interface IKOLFactory {
    /**
     * @dev Get the owner of the KOLFactory contract
     * @return The owner address
     */
    function owner() external view returns (address);

    /**
     * @dev Check if an address is whitelisted as KOL
     * @param kolAddress The address to check
     * @return True if whitelisted
     */
    function isWhitelistedKOL(address kolAddress) external view returns (bool);

    /**
     * @dev Check if an address is an admin
     * @param adminAddress The address to check
     * @return True if admin
     */
    function checkIsAdmin(address adminAddress) external view returns (bool);

    /**
     * @dev Check if a strategy address is whitelisted
     * @param strategyAddress The address to check
     * @return True if whitelisted
     */
    function isStrategyWhitelisted(address strategyAddress) external view returns (bool);

    /**
     * @dev Check if a token address is accepted
     * @param tokenAddress The address to check
     * @return True if accepted
     */
    function isTokenAccepted(address tokenAddress) external view returns (bool);
} 