const selectStakingTokenAddress = async(developmentChains, stakingMainTokenAddress, stakingTestTokenAddress) => {
    if (!developmentChains.includes(network.name)) {
        return stakingMainTokenAddress
    } else {
        return stakingTestTokenAddress
    }
}

module.exports = { selectStakingTokenAddress }