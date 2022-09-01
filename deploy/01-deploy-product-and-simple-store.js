const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("------------------------------")
    const productArgs = ["some://random.uri"]
    const product = await deploy("Product", {
        from: deployer,
        args: productArgs,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    const simpleStoreArgs = [product.address]
    const simpleStore = await deploy("SimpleStore", {
        from: deployer,
        args: simpleStoreArgs,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying contracts...")
        await verify(product.address, args)
        await verify(simpleStore.address, args)
    }
    log("------------------------------")
}

module.exports.tags = ["all"]
