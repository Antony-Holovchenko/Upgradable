const { ethers, upgrades} = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { selectStakingTokenAddress } = require("../utils/helpers")


async function deployStakingRewards() {
    const NSR = await ethers.getContractFactory("NeonStakingRewards")
    // NeonToken proxy address(reward token)
    const rewardTokenAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
    // DAI contract address in Sepolia network(staking token)
    const stakingMainTokenAddress = "0x68194a729C2450ad26072b3D33ADaCbcef39D574"
    // Staking toekn address for local usage/testing
    const stakingTestTokenAddress = (await deployments.get("TestStakingToken")).address


    console.log(`Start deploying StakingRewards proxy...`)
    const nsrProxy = await upgrades.deployProxy(
        NSR,
        [],
        {
          initializer: 'initialize',
          constructorArgs: [
            await selectStakingTokenAddress(developmentChains, stakingMainTokenAddress, stakingTestTokenAddress), 
            rewardTokenAddress]
        }
    )
    await nsrProxy.waitForDeployment()
    console.log(`Successfully deployed NSR proxy at ${await nsrProxy.getAddress()}`)
}


deployStakingRewards()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});
module.exports = { deployStakingRewards }

 