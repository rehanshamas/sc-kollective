const { ethers, upgrades } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🔄 Starting Contract Upgrade...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Upgrading with account:", deployer.address);

  // Get contract name from command line arguments
  const contractName = process.argv[2];
  if (!contractName) {
    console.error("❌ Please provide a contract name to upgrade");
    console.log("Usage: npx hardhat run scripts/upgrade.js --network <network> <contractName>");
    console.log("Available contracts: KOLFactory, KOLFundsManager, KOLKeeper, DhedgeStrategy");
    process.exit(1);
  }

  // Load deployment info
  let deploymentInfo;
  try {
    const deploymentFiles = fs.readdirSync(".").filter(file => file.startsWith("deployment-") && file.endsWith(".json"));
    if (deploymentFiles.length === 0) {
      console.error("❌ No deployment files found");
      process.exit(1);
    }
    
    // Use the most recent deployment file
    const latestDeploymentFile = deploymentFiles.sort().pop();
    deploymentInfo = JSON.parse(fs.readFileSync(latestDeploymentFile, "utf8"));
    console.log("📋 Using deployment file:", latestDeploymentFile);
  } catch (error) {
    console.error("❌ Error loading deployment info:", error.message);
    process.exit(1);
  }

  // Get proxy address
  const proxyAddress = deploymentInfo.contracts[contractName];
  if (!proxyAddress) {
    console.error(`❌ Contract ${contractName} not found in deployment info`);
    console.log("Available contracts:", Object.keys(deploymentInfo.contracts).join(", "));
    process.exit(1);
  }

  console.log(`🔧 Upgrading ${contractName} at address: ${proxyAddress}`);

  // Get current implementation
  const currentImplementation = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("🔍 Current implementation:", currentImplementation);

  try {
    // Deploy new implementation
    console.log(`\n🔧 Deploying new implementation for ${contractName}...`);
    const ContractFactory = await ethers.getContractFactory(contractName);
    
    const upgradedContract = await upgrades.upgradeProxy(proxyAddress, ContractFactory);
    await upgradedContract.waitForDeployment();

    // Get new implementation
    const newImplementation = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("✅ New implementation deployed:", newImplementation);

    // Verify upgrade
    console.log("\n🔍 Verifying upgrade...");
    
    // Test basic functionality based on contract type
    if (contractName === "KOLFactory") {
      const version = await upgradedContract.getVersion();
      const owner = await upgradedContract.owner();
      console.log("📊 KOLFactory Details after upgrade:");
      console.log("   Version:", version.toString());
      console.log("   Owner:", owner);
    } else if (contractName === "KOLFundsManager") {
      const version = await upgradedContract.version;
      const name = await upgradedContract.name;
      console.log("📊 KOLFundsManager Details after upgrade:");
      console.log("   Version:", version.toString());
      console.log("   Name:", name);
    } else if (contractName === "KOLKeeper") {
      const version = await upgradedContract.version;
      const name = await upgradedContract.name;
      console.log("📊 KOLKeeper Details after upgrade:");
      console.log("   Version:", version.toString());
      console.log("   Name:", name);
    } else if (contractName === "DhedgeStrategy") {
      const version = await upgradedContract.version;
      const name = await upgradedContract.name;
      console.log("📊 DhedgeStrategy Details after upgrade:");
      console.log("   Version:", version.toString());
      console.log("   Name:", name);
    }

    console.log(`\n🎉 ${contractName} upgrade completed successfully!`);

    // Update deployment info
    deploymentInfo.implementationAddresses[contractName] = newImplementation;
    deploymentInfo.upgradeHistory = deploymentInfo.upgradeHistory || {};
    deploymentInfo.upgradeHistory[contractName] = {
      previousImplementation: currentImplementation,
      newImplementation: newImplementation,
      upgradeTimestamp: new Date().toISOString(),
    };

    // Save updated deployment info
    const deploymentFileName = `deployment-${hre.network.name}-${Date.now()}.json`;
    fs.writeFileSync(deploymentFileName, JSON.stringify(deploymentInfo, null, 2));
    console.log(`\n💾 Updated deployment info saved to: ${deploymentFileName}`);

    console.log("\n📋 Upgrade Summary:");
    console.log("   Contract:", contractName);
    console.log("   Proxy Address:", proxyAddress);
    console.log("   Old Implementation:", currentImplementation);
    console.log("   New Implementation:", newImplementation);

  } catch (error) {
    console.error(`❌ ${contractName} upgrade failed:`, error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Upgrade failed:", error);
    process.exit(1);
  }); 