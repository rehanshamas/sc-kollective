# Smart Contract Kollective (SC-Kollective)

A modern, production-ready Hardhat development environment for Solidity smart contracts with the latest tools and best practices, featuring a simple upgradable contract template.

## 🚀 Features

- **Latest Hardhat v2.26.1** with modern tooling
- **Solidity v0.8.30** with optimizer and viaIR enabled
- **OpenZeppelin Contracts v5.4.0** for secure, audited contracts
- **Upgradeable Contracts** with UUPS proxy pattern
- **Node.js v20+** support with engine requirements
- **Comprehensive testing** with Hardhat testing framework
- **Gas reporting** and contract size analysis
- **Code linting** with Solhint
- **Environment variable** management with dotenv
- **Multi-network deployment** support
- **Contract verification** ready for block explorers

## 📋 Prerequisites

- Node.js v20.0.0 or higher
- npm v10.0.0 or higher
- Git

## 🛠️ Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd sc-kollective
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

## 🏗️ Project Structure

```
sc-kollective/
├── contracts/           # Smart contracts
│   └── KOLFactory.sol  # Simple upgradable contract template
├── scripts/            # Deployment and utility scripts
│   ├── deploy-kolfactory.js    # Main deployment script
│   └── upgrade-kolfactory.js   # Upgrade script
├── test/               # Test files
├── hardhat.config.js   # Hardhat configuration
├── .solhint.json       # Solidity linting rules
├── env.example         # Environment variables template
└── package.json        # Project dependencies and scripts
```

## 🎯 Available Scripts

### Development
```bash
npm run compile         # Compile contracts
npm run test           # Run tests
npm run test:gas       # Run tests with gas reporting
npm run node           # Start local Hardhat node
npm run clean          # Clean build artifacts
```

### Deployment
```bash
npm run deploy:kickstarter         # Deploy to default network
npm run deploy:kickstarter:local   # Deploy to localhost
npm run deploy:kickstarter:sepolia # Deploy to Sepolia testnet
npm run deploy:kickstarter:mainnet # Deploy to Ethereum mainnet
```

### Upgrades
```bash
npm run upgrade:kickstarter         # Upgrade on default network
npm run upgrade:kickstarter:local   # Upgrade on localhost
npm run upgrade:kickstarter:sepolia # Upgrade on Sepolia testnet
npm run upgrade:kickstarter:mainnet # Upgrade on Ethereum mainnet
```

### Code Quality
```bash
npm run lint           # Lint Solidity code
npm run lint:fix       # Fix linting issues
npm run coverage       # Run test coverage
npm run size           # Analyze contract sizes
```

## 🔧 Configuration

### Hardhat Configuration
The project is configured with:
- **Solidity optimizer** enabled (200 runs)
- **viaIR** compilation for better optimization
- **Multi-network support** (Hardhat, localhost, mainnet, testnets)
- **Gas reporting** with USD pricing
- **Contract size analysis**
- **Upgradeable contracts** support

### Environment Variables
Create a `.env` file with:
```env
# Network RPC URLs
MAINNET_RPC_URL=your_mainnet_rpc_url
SEPOLIA_RPC_URL=your_sepolia_rpc_url

# Private Keys (never commit to git!)
PRIVATE_KEY=your_private_key

# API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key

# Gas Reporter
REPORT_GAS=true
COINMARKETCAP_API_KEY=your_coinmarketcap_api_key
```

## 📝 Smart Contracts

### KOLFactory
A simple upgradable contract template with minimal functionality:
- **UUPS Upgradeable** pattern for future upgrades
- **Access control** with OpenZeppelin Ownable
- **Initializer function** for contract setup
- **Version tracking** for upgrade management
- **Basic state variables** (name, version)

#### Key Features:
- **`initialize()`** - Sets up the contract with owner and name
- **`getVersion()`** - Returns current contract version
- **`_authorizeUpgrade()`** - Internal function for upgrade authorization
- **Upgradeable** - Can be upgraded to add new functionality

## 🧪 Testing

Run the test suite:
```bash
npm test
```

The project is ready for comprehensive testing of your smart contracts.

## 🚀 Deployment

### Local Development
1. Start a local Hardhat node:
   ```bash
   npm run node
   ```

2. Deploy the contract:
   ```bash
   npm run deploy:kickstarter:local
   ```

### Testnet/Mainnet Deployment
1. Configure your `.env` file with appropriate RPC URLs and private keys
2. Deploy to testnet:
   ```bash
   npm run deploy:kickstarter:sepolia
   ```
3. Deploy to mainnet:
   ```bash
   npm run deploy:kickstarter:mainnet
   ```

## 🔄 Contract Upgrades

The KOLFactory contract is upgradeable using the UUPS pattern:

1. **Deploy new implementation**:
   ```bash
   npm run upgrade:kickstarter:sepolia
   ```

2. **Verify upgrade**:
   - Check that existing functionality still works
   - Verify new features are available
   - Test with existing data

## 🔍 Contract Verification

After deployment, verify your contracts on Etherscan:
```bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS [constructor_args]
```

## 📊 Gas Optimization

The project includes gas optimization features:
- **Solidity optimizer** enabled
- **Gas reporting** in tests
- **Contract size analysis**
- **Best practices** implementation

## 🛡️ Security

- **OpenZeppelin contracts** for audited, secure implementations
- **Access control** with proper modifiers
- **Input validation** and error handling
- **Code linting** with security-focused rules
- **Upgradeable pattern** for future security patches

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the Hardhat documentation
- Review OpenZeppelin documentation

## 🔗 Useful Links

- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Ethereum Development](https://ethereum.org/developers/)
