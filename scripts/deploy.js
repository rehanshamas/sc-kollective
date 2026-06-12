const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("🚀 Starting KOLlective Protocol Deployment...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    contracts: {},
    implementationAddresses: {},
    adminAddresses: {},
    timestamp: new Date().toISOString(),
    version: "1.0.0"
  };

  try {
    // Step 1: Deploy DhedgeStrategy (implementation only - will be cloned)
    console.log("\n🔧 Step 1: Deploying DhedgeStrategy (implementation only)...");
    const DhedgeStrategy = await ethers.getContractFactory("DhedgeStrategy");
    const dhedgeStrategy = await DhedgeStrategy.deploy();
    await dhedgeStrategy.waitForDeployment();
    const dhedgeStrategyAddress = await dhedgeStrategy.getAddress();
    console.log("✅ DhedgeStrategy implementation deployed to:", dhedgeStrategyAddress);
    deploymentInfo.implementationAddresses.DhedgeStrategy = dhedgeStrategyAddress;

    // Step 2: Deploy KOLKeeper (implementation only - will be cloned by KOLFactory)
    console.log("\n🔧 Step 2: Deploying KOLKeeper (implementation only)...");
    const KOLKeeper = await ethers.getContractFactory("KOLKeeper");
    const kolKeeper = await KOLKeeper.deploy();
    await kolKeeper.waitForDeployment();
    const kolKeeperAddress = await kolKeeper.getAddress();
    console.log("✅ KOLKeeper implementation deployed to:", kolKeeperAddress);
    deploymentInfo.implementationAddresses.KOLKeeper = kolKeeperAddress;

    // Step 3: Deploy KOLFactory (upgradeable)
    console.log("\n🔧 Step 3: Deploying KOLFactory (upgradeable)...");
    const KOLFactory = await ethers.getContractFactory("KOLFactory");
    const kolFactory = await upgrades.deployProxy(KOLFactory, [
      deployer.address,
      "KOL Factory",
      kolKeeperAddress
    ], {
      initializer: "initialize(address,string,address)",
      kind: "uups"
    });
    await kolFactory.waitForDeployment();
    const kolFactoryAddress = await kolFactory.getAddress();
    console.log("✅ KOLFactory deployed to:", kolFactoryAddress);
    deploymentInfo.contracts.KOLFactory = kolFactoryAddress;
    deploymentInfo.implementationAddresses.KOLFactory = await upgrades.erc1967.getImplementationAddress(kolFactoryAddress);
    deploymentInfo.adminAddresses.KOLFactory = await upgrades.erc1967.getAdminAddress(kolFactoryAddress);

    // Step 4: Deploy KOLFundsManager (upgradeable)
    console.log("\n🔧 Step 4: Deploying KOLFundsManager (upgradeable)...");
    const KOLFundsManager = await ethers.getContractFactory("KOLFundsManager");
    const kolFundsManager = await upgrades.deployProxy(KOLFundsManager, [
      deployer.address,
      "KOL Funds Manager",
      kolFactoryAddress // Now we can pass the actual KOLFactory address
    ], {
      initializer: "initialize(address,string,address)",
      kind: "uups"
    });
    await kolFundsManager.waitForDeployment();
    const kolFundsManagerAddress = await kolFundsManager.getAddress();
    console.log("✅ KOLFundsManager deployed to:", kolFundsManagerAddress);
    deploymentInfo.contracts.KOLFundsManager = kolFundsManagerAddress;
    deploymentInfo.implementationAddresses.KOLFundsManager = await upgrades.erc1967.getImplementationAddress(kolFundsManagerAddress);
    deploymentInfo.adminAddresses.KOLFundsManager = await upgrades.erc1967.getAdminAddress(kolFundsManagerAddress);

    // Step 5: Configure cross-contract references
    console.log("\n🔧 Step 5: Configuring cross-contract references...");
    
    // Set fundsManager in KOLFactory
    console.log("   Setting fundsManager in KOLFactory...");
    await kolFactory.setFundsManager(kolFundsManagerAddress);
    console.log("   ✅ fundsManager set in KOLFactory");

    // Note: DhedgeStrategy is deployed as implementation and will be cloned when needed
    // KOLKeeper is deployed as implementation and will be cloned by KOLFactory
    console.log("   ℹ️  DhedgeStrategy and KOLKeeper deployed as implementations - will be cloned when needed");

    // Step 6: Initial setup and testing
    console.log("\n🔧 Step 6: Initial setup and testing...");
    
    // Verify contract configurations
    console.log("   Verifying contract configurations...");
    
    const factoryOwner = await kolFactory.owner();
    const factoryName = await kolFactory.name();
    const factoryVersion = await kolFactory.getVersion();
    
    console.log("   📊 KOLFactory Details:");
    console.log("     Owner:", factoryOwner);
    console.log("     Name:", factoryName);
    console.log("     Version:", factoryVersion.toString());
    console.log("     Keeper Implementation:", await kolFactory.keeperImplementation());
    console.log("     Funds Manager:", await kolFactory.fundsManager());

    // Test basic functionality
    console.log("\n🧪 Testing basic functionality...");
    
    // Test admin functions
    console.log("   Testing admin functions...");
    const isDeployerAdmin = await kolFactory.checkIsAdmin(deployer.address);
    console.log("     Deployer is admin:", isDeployerAdmin);

    // Test protocol whitelist
    console.log("   Testing protocol whitelist...");
    const testProtocol = "0x1234567890123456789012345678901234567890";
    await kolFactory.setProtocolWhitelist(testProtocol, true);
    const isProtocolWhitelisted = await kolFactory.isProtocolWhitelisted(testProtocol);
    console.log("     Test protocol whitelisted:", isProtocolWhitelisted);

    console.log("\n🎉 Deployment completed successfully!");

    // Save deployment info
    const deploymentFileName = `deployment-${hre.network.name}-${Date.now()}.json`;
    fs.writeFileSync(deploymentFileName, JSON.stringify(deploymentInfo, null, 2));
    console.log(`\n💾 Deployment info saved to: ${deploymentFileName}`);

    // Display summary
    console.log("\n📋 Deployment Summary:");
    console.log("   Network:", hre.network.name);
    console.log("   Deployer:", deployer.address);
    console.log("   KOLFactory (Proxy):", kolFactoryAddress);
    console.log("   KOLFundsManager (Proxy):", kolFundsManagerAddress);
    console.log("   KOLKeeper (Implementation):", kolKeeperAddress);
    console.log("   DhedgeStrategy (Implementation):", dhedgeStrategyAddress);

    console.log("\n🔧 Upgrade Information:");
    console.log("   KOLFactory Implementation:", deploymentInfo.implementationAddresses.KOLFactory);
    console.log("   KOLFundsManager Implementation:", deploymentInfo.implementationAddresses.KOLFundsManager);
    console.log("   KOLKeeper Implementation:", deploymentInfo.implementationAddresses.KOLKeeper);
    console.log("   DhedgeStrategy Implementation:", deploymentInfo.implementationAddresses.DhedgeStrategy);

    // Step 7: Auto-verify contracts (skip for localhost/hardhat networks)
    if (hre.network.name !== "localhost" && hre.network.name !== "hardhat") {
      console.log("\n🔧 Step 7: Auto-verifying contracts on Etherscan...");
      try {
        console.log("   Starting automatic verification...");
        await hre.run("verify:verify", {
          address: deploymentInfo.implementationAddresses.DhedgeStrategy,
          constructorArguments: [],
        });
        console.log("   ✅ DhedgeStrategy implementation verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  DhedgeStrategy already verified");
        } else {
          console.log("   ⚠️  DhedgeStrategy verification failed:", error.message);
        }
      }

      try {
        await hre.run("verify:verify", {
          address: deploymentInfo.implementationAddresses.KOLKeeper,
          constructorArguments: [],
        });
        console.log("   ✅ KOLKeeper implementation verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  KOLKeeper already verified");
        } else {
          console.log("   ⚠️  KOLKeeper verification failed:", error.message);
        }
      }

      try {
        await hre.run("verify:verify", {
          address: deploymentInfo.implementationAddresses.KOLFactory,
          constructorArguments: [],
          contract: "contracts/KOLFactory.sol:KOLFactory",
        });
        console.log("   ✅ KOLFactory implementation verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  KOLFactory implementation already verified");
        } else {
          console.log("   ⚠️  KOLFactory implementation verification failed:", error.message);
        }
      }

      try {
        await hre.run("verify:verify", {
          address: deploymentInfo.implementationAddresses.KOLFundsManager,
          constructorArguments: [],
          contract: "contracts/KOLFundsManager.sol:KOLFundsManager",
        });
        console.log("   ✅ KOLFundsManager implementation verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  KOLFundsManager implementation already verified");
        } else {
          console.log("   ⚠️  KOLFundsManager implementation verification failed:", error.message);
        }
      }

      try {
        await hre.run("verify:verify", {
          address: deploymentInfo.contracts.KOLFactory,
          constructorArguments: [],
          contract: "contracts/KOLFactory.sol:KOLFactory",
        });
        console.log("   ✅ KOLFactory proxy verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  KOLFactory proxy already verified");
        } else {
          console.log("   ⚠️  KOLFactory proxy verification failed:", error.message);
        }
      }

      try {
        await hre.run("verify:verify", {
          address: deploymentInfo.contracts.KOLFundsManager,
          constructorArguments: [],
          contract: "contracts/KOLFundsManager.sol:KOLFundsManager",
        });
        console.log("   ✅ KOLFundsManager proxy verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  KOLFundsManager proxy already verified");
        } else {
          console.log("   ⚠️  KOLFundsManager proxy verification failed:", error.message);
        }
      }

      console.log("   🎉 Auto-verification completed!");
    } else {
      console.log("\n🔧 Step 7: Skipping auto-verification (localhost/hardhat network)");
    }

  } catch (error) {
    console.error("❌ Deployment failed:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 