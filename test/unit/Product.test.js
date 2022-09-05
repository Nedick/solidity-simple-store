const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Product Unit Tests", function () {
          const PRODUCT_ID = 1
          const PRODUCT_QUANTITY = 11

          beforeEach(async () => {
              accounts = await ethers.getSigners() // could also do with getNamedAccounts
              owner = accounts[0]
              user = accounts[1]
              await deployments.fixture(["all"])
              productContract = await ethers.getContract("Product")
              product = productContract.connect(owner)
              simpleStoreContract = await ethers.getContract("SimpleStore")
          })

          describe("addProduct", function () {
              it("Emits an event after adding or updating a product", async function () {
                  expect(await product.addProduct(PRODUCT_ID, PRODUCT_QUANTITY)).to.emit(
                      "ItemUpdate"
                  )
              })
              it("Allows only the owner to add or update a product", async function () {
                  product = productContract.connect(user)
                  await expect(product.addProduct(PRODUCT_ID, PRODUCT_QUANTITY)).to.be.revertedWith(
                      "NotOwnerOfContract"
                  )
              })
          })

          describe("grantAccessToSimpleStoreContract", function () {
              it("Grants access for SimpleStore contract", async function () {
                  expect(
                      await product.grantAccessToSimpleStoreContract(simpleStoreContract.address)
                  ).to.emit("GrantedAccessToProducts")
              })
          })

          describe("getUniqueProductsIds", function () {
              it("Check if added product id's are unique ", async function () {
                  // add 2 times product with same id
                  await product.addProduct(PRODUCT_ID, PRODUCT_QUANTITY)
                  await product.addProduct(PRODUCT_ID, PRODUCT_QUANTITY)
                  productIds = await product.getUniqueProductsIds()
                  console.log(productIds.toString())
                  assert(productIds.toString() == 1)
              })
          })
      })
