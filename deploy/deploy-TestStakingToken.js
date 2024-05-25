const { deployments, getNamedAccounts } = require("hardhat")

module.exports = async() => {
    const { deployer } = await getNamedAccounts()
    const { deploy, log } = deployments

    console.log("Start deploying test staking token...")

    const deployTestToken = await deploy("TestStakingToken", {
        from: deployer,
        log: false,
        args: []
    })

    console.log(`Deployed test staking token at: ${deployTestToken.address}`)
}

//module.exports = { deployTestStakingToken }

module.exports.tags = ["all", "TestStakingToken"]