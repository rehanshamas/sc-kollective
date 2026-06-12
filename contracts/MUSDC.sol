// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MUSDC is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18; // 1 million tokens with 18 decimals
    
    constructor() ERC20("Mock USDC", "mUSDC") Ownable(0x48f9d844364095B1B0B9429A18ec9B4fA5c6Af41) {
        // Mint half supply to 0xAFD3A045b41Bd860d4C18F10481bAd8eF4cF08ac
        _mint(0xAFD3A045b41Bd860d4C18F10481bAd8eF4cF08ac, TOTAL_SUPPLY / 2);
        
        // Mint half supply to owner (0x48f9d844364095B1B0B9429A18ec9B4fA5c6Af41)
        _mint(0x48f9d844364095B1B0B9429A18ec9B4fA5c6Af41, TOTAL_SUPPLY / 2);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function decimals() public pure override returns (uint8) {
        return 18;
    }
} 