// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title KOLStrategyBase
 * @dev Base contract for KOL strategies with ERC20 and ERC1155 receiver capabilities
 * @custom:security-contact security@kollective.com
 */
abstract contract KOLStrategyBase is 
    Initializable, 
    IERC1155Receiver 
{
    using SafeERC20 for IERC20;

    // Events
    event TokensReceived(address indexed token, address indexed from, uint256 amount);

    // State variables
    string public name;
    uint256 public version;
    address public fundsManager;

    // Modifiers
    modifier onlyFundsManager() {
        require(msg.sender == fundsManager, "Caller is not the funds manager");
        _;
    }

    /**
     * @dev Initializes the strategy base contract
     * @param _fundsManager The funds manager address
     */
    function initialize(
        address _fundsManager
    ) public virtual initializer {
        version = 1;
        fundsManager = _fundsManager;
    }

    /**
     * @dev Invest funds into the strategy (only funds manager)
     * @param token The token address to invest
     * @param amount The amount to invest
     */
    function invest(address token, uint256 amount) external virtual onlyFundsManager {
        // Implementation will be added later
    }

    /**
     * @dev Harvest rewards from the strategy (only funds manager)
     * @param token The token address to harvest
     */
    function harvest(address token) external virtual onlyFundsManager {
        // Implementation will be added later
    }

    /**
     * @dev Withdraw all funds from the strategy (only funds manager)
     * @param token The token address to withdraw
     */
    function withdrawAll(address token) external virtual onlyFundsManager {
        // Implementation will be added later
    }

    /**
     * @dev Emergency function to recover stuck tokens (only owner - to be implemented by derived contracts)
     * @param token The token address to recover
     * @param amount The amount to recover
     * @param recipient The recipient address
     */
    function emergencyRecover(address token, uint256 amount, address recipient) external virtual {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * @dev Function to receive ETH
     */
    receive() external payable {
        // Strategy can receive ETH
    }

    /**
     * @dev Fallback function to receive ETH
     */
    fallback() external payable {
        // Strategy can receive ETH
    }

    /**
     * @dev ERC1155 receiver function
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        emit TokensReceived(address(0), from, value); // address(0) for ERC1155
        return this.onERC1155Received.selector;
    }

    /**
     * @dev ERC1155 batch receiver function
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Check if contract supports ERC1155 receiver interface
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}