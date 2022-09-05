const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("SimpleStore Unit Tests", function () {
          const PRICE = ethers.utils.parseEther("0.1")
          const PRODUCT_ID = 1
          const PRODUCT_QUANTITY = 11
          const PRODUCTS_PER_ORDER = 1

          beforeEach(async () => {
              accounts = await ethers.getSigners() // could also do with getNamedAccounts
              owner = accounts[0]
              user = accounts[1]
              await deployments.fixture(["all"])
              productContract = await ethers.getContract("Product")
              product = productContract.connect(owner)
              simpleStoreContract = await ethers.getContract("SimpleStore")
              simpleStore = simpleStoreContract.connect(user)
              // give simpleStore contract privileges to transfer Product tokens
              await productContract.grantAccessToSimpleStoreContract(simpleStoreContract.address)
              await productContract.addProduct(PRODUCT_ID, PRODUCT_QUANTITY)
          })

          describe("buyProduct", function () {
              it("Revert if price of purchase < 0.01 ethers", async function () {
                  await simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })
                  await expect(
                      simpleStore.buyProduct(PRODUCT_ID, { value: 100000 })
                  ).to.be.revertedWith("PriceTooLow")
              })
              it("Revert if user already bought that item", async function () {
                  await simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })
                  await expect(
                      simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })
                  ).to.be.revertedWith("AlreadyBoughtThatItem")
              })
              it("Check if product was transferred to the new owner", async function () {
                  await simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })
                  userBalance = await productContract.balanceOf(user.address, PRODUCT_ID)
                  assert(userBalance.toString() == PRODUCTS_PER_ORDER)
              })
              it("Check if SimpleStore Product quantity is one less after purchase", async function () {
                  await simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })
                  productBalance = await productContract.balanceOf(owner.address, PRODUCT_ID)
                  expectedBalance = PRODUCT_QUANTITY - PRODUCTS_PER_ORDER
                  assert(productBalance.toString() == expectedBalance)
              })
              it("Emits an event after buying a product", async function () {
                  const event = `ItemBought("${(owner, user, PRODUCT_ID, PRODUCTS_PER_ORDER)}")`
                  expect(await simpleStore.buyProduct(PRODUCT_ID, { value: PRICE })).to.emit(event)
              })
          })
      })
