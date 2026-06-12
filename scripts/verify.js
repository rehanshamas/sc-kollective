const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function verifyContract(address, contractPath = null, constructorArgs = []) {
  try {
    const verifyOptions = {
      address: address,
      constructorArguments: constructorArgs,
    };
    
    if (contractPath) {
      verifyOptions.contract = contractPath;
    }
    
    await hre.run("verify:verify", verifyOptions);
    return true;
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("   ℹ️  Contract already verified");
      return true;
    } else {
      throw error;
    }
  }
}

async function main() {
  const network = hre.network.name;
  console.log(`🔍 Starting contract verification for network: ${network}`);

  // Find the most recent deployment file for this network
  const deploymentFiles = fs.readdirSync(".")
    .filter(file => file.startsWith(`deployment-${network}-`) && file.endsWith(".json"))
    .sort()
    .reverse();

  if (deploymentFiles.length === 0) {
    console.error(`❌ No deployment files found for network: ${network}`);
    console.log("Available deployment files:");
    const allDeploymentFiles = fs.readdirSync(".")
      .filter(file => file.startsWith("deployment-") && file.endsWith(".json"));
    allDeploymentFiles.forEach(file => console.log(`  - ${file}`));
    process.exit(1);
  }

  const deploymentFile = deploymentFiles[0];
  console.log(`📁 Using deployment file: ${deploymentFile}`);

  // Read deployment info
  const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  console.log(`📅 Deployment timestamp: ${deploymentInfo.timestamp}`);

  try {
    // Verify implementation contracts first
    console.log("\n🔧 Step 1: Verifying implementation contracts...");
    
    // Verify DhedgeStrategy implementation
    if (deploymentInfo.implementationAddresses.DhedgeStrategy) {
      console.log("   Verifying DhedgeStrategy implementation...");
      await verifyContract(deploymentInfo.implementationAddresses.DhedgeStrategy);
      console.log("   ✅ DhedgeStrategy implementation verified");
    }

    // Verify KOLKeeper implementation
    if (deploymentInfo.implementationAddresses.KOLKeeper) {
      console.log("   Verifying KOLKeeper implementation...");
      await verifyContract(deploymentInfo.implementationAddresses.KOLKeeper);
      console.log("   ✅ KOLKeeper implementation verified");
    }

    // Verify proxy contracts
    console.log("\n🔧 Step 2: Verifying proxy contracts...");
    
    // Verify KOLFactory proxy
    if (deploymentInfo.contracts.KOLFactory) {
      console.log("   Verifying KOLFactory proxy...");
      await verifyContract(deploymentInfo.contracts.KOLFactory, "contracts/KOLFactory.sol:KOLFactory");
      console.log("   ✅ KOLFactory proxy verified");
    }

    // Verify KOLFundsManager proxy
    if (deploymentInfo.contracts.KOLFundsManager) {
      console.log("   Verifying KOLFundsManager proxy...");
      await verifyContract(deploymentInfo.contracts.KOLFundsManager, "contracts/KOLFundsManager.sol:KOLFundsManager");
      console.log("   ✅ KOLFundsManager proxy verified");
    }

    // Verify implementation addresses for proxy contracts
    console.log("\n🔧 Step 3: Verifying proxy implementation contracts...");
    
    // Verify KOLFactory implementation
    if (deploymentInfo.implementationAddresses.KOLFactory) {
      console.log("   Verifying KOLFactory implementation...");
      await verifyContract(deploymentInfo.implementationAddresses.KOLFactory, "contracts/KOLFactory.sol:KOLFactory");
      console.log("   ✅ KOLFactory implementation verified");
    }

    // Verify KOLFundsManager implementation
    if (deploymentInfo.implementationAddresses.KOLFundsManager) {
      console.log("   Verifying KOLFundsManager implementation...");
      await verifyContract(deploymentInfo.implementationAddresses.KOLFundsManager, "contracts/KOLFundsManager.sol:KOLFundsManager");
      console.log("   ✅ KOLFundsManager implementation verified");
    }

    console.log("\n🎉 All contracts verified successfully!");
    
    // Display verification summary
    console.log("\n📋 Verification Summary:");
    console.log("   Network:", network);
    console.log("   Deployment File:", deploymentFile);
    console.log("   Implementation Contracts:");
    console.log("     DhedgeStrategy:", deploymentInfo.implementationAddresses.DhedgeStrategy);
    console.log("     KOLKeeper:", deploymentInfo.implementationAddresses.KOLKeeper);
    console.log("   Proxy Contracts:");
    console.log("     KOLFactory:", deploymentInfo.contracts.KOLFactory);
    console.log("     KOLFundsManager:", deploymentInfo.contracts.KOLFundsManager);
    console.log("   Implementation Addresses:");
    console.log("     KOLFactory Implementation:", deploymentInfo.implementationAddresses.KOLFactory);
    console.log("     KOLFundsManager Implementation:", deploymentInfo.implementationAddresses.KOLFundsManager);

    // Generate Etherscan links
    const etherscanBaseUrl = getEtherscanBaseUrl(network);
    if (etherscanBaseUrl) {
      console.log("\n🔗 Etherscan Links:");
      console.log("   DhedgeStrategy Implementation:", `${etherscanBaseUrl}/address/${deploymentInfo.implementationAddresses.DhedgeStrategy}`);
      console.log("   KOLKeeper Implementation:", `${etherscanBaseUrl}/address/${deploymentInfo.implementationAddresses.KOLKeeper}`);
      console.log("   KOLFactory Proxy:", `${etherscanBaseUrl}/address/${deploymentInfo.contracts.KOLFactory}`);
      console.log("   KOLFundsManager Proxy:", `${etherscanBaseUrl}/address/${deploymentInfo.contracts.KOLFundsManager}`);
      console.log("   KOLFactory Implementation:", `${etherscanBaseUrl}/address/${deploymentInfo.implementationAddresses.KOLFactory}`);
      console.log("   KOLFundsManager Implementation:", `${etherscanBaseUrl}/address/${deploymentInfo.implementationAddresses.KOLFundsManager}`);
    }

  } catch (error) {
    console.error("❌ Verification failed:", error.message);
    
    // Provide helpful error information
    if (error.message.includes("No bytecode")) {
      console.log("ℹ️  Contract not found on network - check if deployment was successful");
    } else if (error.message.includes("API key")) {
      console.log("ℹ️  Check your Etherscan API key configuration");
    }
    
    throw error;
  }
}

function getEtherscanBaseUrl(network) {
  switch (network) {
    case "sepolia":
      return "https://sepolia.etherscan.io";
    case "holesky":
      return "https://holesky.etherscan.io";
    case "mainnet":
      return "https://etherscan.io";
    case "localhost":
    case "hardhat":
      return null;
    default:
      return null;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Verification failed:", error);
    process.exit(1);
  }); 