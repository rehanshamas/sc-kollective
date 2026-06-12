const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Starting MUSDC Mock Token Deployment...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    contract: "MUSDC",
    timestamp: new Date().toISOString(),
    version: "1.0.0"
  };

  try {
    // Deploy MUSDC token
    console.log("\n🔧 Deploying MUSDC Mock Token...");
    const MUSDC = await ethers.getContractFactory("MUSDC");
    const musdc = await MUSDC.deploy();
    await musdc.waitForDeployment();
    const musdcAddress = await musdc.getAddress();
    
    console.log("✅ MUSDC deployed to:", musdcAddress);
    deploymentInfo.address = musdcAddress;
    deploymentInfo.implementationAddress = musdcAddress;

    // Get contract details
    const name = await musdc.name();
    const symbol = await musdc.symbol();
    const decimals = await musdc.decimals();
    const totalSupply = await musdc.totalSupply();
    const owner = await musdc.owner();

    console.log("\n📊 MUSDC Token Details:");
    console.log("   Name:", name);
    console.log("   Symbol:", symbol);
    console.log("   Decimals:", decimals.toString());
    console.log("   Total Supply:", ethers.formatUnits(totalSupply, decimals));
    console.log("   Owner:", owner);

    // Check balances of specified addresses
    const address1 = "0xAFD3A045b41Bd860d4C18F10481bAd8eF4cF08ac";
    const address2 = "0x48f9d844364095B1B0B9429A18ec9B4fA5c6Af41";
    
    const balance1 = await musdc.balanceOf(address1);
    const balance2 = await musdc.balanceOf(address2);
    
    console.log("\n💰 Token Distribution:");
    console.log(`   ${address1}:`, ethers.formatUnits(balance1, decimals));
    console.log(`   ${address2}:`, ethers.formatUnits(balance2, decimals));

    // Save deployment info
    const deploymentFileName = `deployment-musdc-${hre.network.name}-${Date.now()}.json`;
    fs.writeFileSync(deploymentFileName, JSON.stringify(deploymentInfo, null, 2));
    console.log(`\n💾 Deployment info saved to: ${deploymentFileName}`);

    // Auto-verify contract (skip for localhost/hardhat networks)
    if (hre.network.name !== "localhost" && hre.network.name !== "hardhat") {
      console.log("\n🔧 Auto-verifying contract on Etherscan...");
      try {
        await hre.run("verify:verify", {
          address: musdcAddress,
          constructorArguments: [],
        });
        console.log("   ✅ MUSDC contract verified");
      } catch (error) {
        if (error.message.includes("Already Verified")) {
          console.log("   ℹ️  MUSDC contract already verified");
        } else {
          console.log("   ⚠️  MUSDC verification failed:", error.message);
        }
      }
    } else {
      console.log("\n🔧 Skipping auto-verification (localhost/hardhat network)");
    }

    console.log("\n🎉 MUSDC deployment completed successfully!");

  } catch (error) {
    console.error("❌ MUSDC deployment failed:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ MUSDC deployment failed:", error);
    process.exit(1);
  }); 