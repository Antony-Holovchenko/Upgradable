
const { ethers, upgrades} = require("hardhat")

async function deployNeonToken() {
    const tokenFactory = await ethers.getContractFactory("NeonToken")
    
    console.log("Start deploying proxy contract...")
    
    const tokenProxy = await upgrades.deployProxy(
        tokenFactory, 
        [],
        {initializer: "initialize"}
    )
    await tokenProxy.waitForDeployment()

    console.log(`Deployed Neon Token proxy at: ${await tokenProxy.getAddress()} \n`)
    return await tokenProxy.getAddress();
}

deployNeonToken()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});

module.exports = { deployNeonToken }