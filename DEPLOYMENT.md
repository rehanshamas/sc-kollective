# KOLlective Protocol Deployment Guide

This guide explains how to deploy the KOLlective Protocol contracts to different networks.

## Prerequisites

1. **Node.js v20+** installed
2. **Hardhat** project setup complete
3. **Environment variables** configured

## Environment Setup

1. Copy the example environment file:
   ```bash
   cp env.example .env
   ```

2. Configure your `.env` file with the following variables:

   ```env
   # Network RPC URLs
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
   HOLESKY_RPC_URL=https://holesky.infura.io/v3/YOUR_PROJECT_ID
   
   # Private Keys (never commit these to git!)
   PRIVATE_KEY=your_private_key_here
   
   # API Keys
   ETHERSCAN_API_KEY=your_etherscan_api_key
   
   # Gas Reporter
   REPORT_GAS=true
   COINMARKETCAP_API_KEY=your_coinmarketcap_api_key
   ```

## RPC URL Providers

You can get RPC URLs from:
- **Infura**: https://infura.io/
- **Alchemy**: https://alchemy.com/
- **QuickNode**: https://quicknode.com/
- **Ankr**: https://ankr.com/

## Deployment Commands

### Using npm scripts (Recommended)
```bash
# Deploy to Sepolia Testnet
npm run deploy:sepolia

# Deploy to Holesky Testnet
npm run deploy:holesky

# Deploy to Local Network
npm run deploy:local
```

### Using Hardhat directly
```bash
# Deploy to Sepolia Testnet
npx hardhat run scripts/deploy.js --network sepolia

# Deploy to Holesky Testnet
npx hardhat run scripts/deploy.js --network holesky

# Deploy to Local Network
npx hardhat run scripts/deploy.js --network localhost
```

## Deployment Output

After successful deployment, the script will:
1. **Save deployment details** to a JSON file: `deployment-{network}-{timestamp}.json`
2. **Display contract addresses** for all deployed contracts
3. **Show upgrade information** for upgradeable contracts
4. **Test basic functionality** to ensure deployment was successful

## Contract Addresses

The deployment will create the following contracts:
- **KOLFactory**: Main factory contract
- **KOLFundsManager**: Funds management contract
- **KOLKeeper**: Keeper template contract
- **DhedgeStrategy**: Strategy implementation contract

## Upgrade Contracts

### Using npm scripts (Recommended)
```bash
# Upgrade contracts on Sepolia
npm run upgrade:sepolia KOLFactory
npm run upgrade:sepolia KOLFundsManager
npm run upgrade:sepolia KOLKeeper
npm run upgrade:sepolia DhedgeStrategy

# Upgrade contracts on Holesky
npm run upgrade:holesky KOLFactory
npm run upgrade:holesky KOLFundsManager
npm run upgrade:holesky KOLKeeper
npm run upgrade:holesky DhedgeStrategy
```

### Using Hardhat directly
```bash
npx hardhat run scripts/upgrade.js --network sepolia KOLFactory
npx hardhat run scripts/upgrade.js --network sepolia KOLFundsManager
npx hardhat run scripts/upgrade.js --network sepolia KOLKeeper
npx hardhat run scripts/upgrade.js --network sepolia DhedgeStrategy
```

## Verification

After deployment, you can verify contracts on Etherscan:

```bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS
```

## Network Information

### Sepolia Testnet
- **Chain ID**: 11155111
- **Block Explorer**: https://sepolia.etherscan.io/
- **Faucet**: https://sepoliafaucet.com/

### Holesky Testnet
- **Chain ID**: 17000
- **Block Explorer**: https://holesky.etherscan.io/
- **Faucet**: https://holesky-faucet.pk910.de/

## Troubleshooting

### Common Issues

1. **Insufficient Balance**: Ensure your account has enough ETH for deployment
2. **RPC URL Issues**: Verify your RPC URL is correct and accessible
3. **Private Key**: Ensure your private key is correctly set in `.env`
4. **Gas Issues**: Adjust gas price in `hardhat.config.js` if needed

### Gas Optimization

The contracts are optimized for gas efficiency:
- **KOLFactory**: ~8.1 KiB
- **KOLFundsManager**: ~7.6 KiB
- **KOLKeeper**: ~5.4 KiB
- **DhedgeStrategy**: ~4.8 KiB

## Security Notes

- ⚠️ **Never commit private keys** to version control
- ⚠️ **Use testnet private keys** for testing
- ⚠️ **Verify contracts** after deployment
- ⚠️ **Test thoroughly** before mainnet deployment

## Support

For issues or questions:
1. Check the deployment logs for error messages
2. Verify all environment variables are set correctly
3. Ensure sufficient balance in your deployment account
4. Check network connectivity and RPC URL validity 