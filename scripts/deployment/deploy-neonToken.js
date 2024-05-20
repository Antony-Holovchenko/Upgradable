const { ethers, upgrades} = require("hardhat")

async function main() {
    const tokenFactory = await ethers.getContractFactory("NeonToken")
    
    console.log("Start deploying proxy contract...")
    
    const tokenProxy = await upgrades.deployProxy(
        tokenFactory, 
        ["Neon", "NEO"],
        {initializer: "initialize"}
    )
    await tokenProxy.waitForDeployment()
    console.log(`Successfully deployed Neon proxy`)
    
}

main()

