// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Product.sol";

/** 
Using Remix develop a contract for a TechnoLime Store.

- The administrator (owner) of the store should be able to add new products and the quantity of them. -Done!
- The administrator should not be able to add the same product twice, just quantity.                  -Done!
- Buyers (clients) should be able to see the available products and buy them by their id.             -Done!
- Buyers should be able to return products if they are not satisfied
(within a certain period in blocktime: 100 blocks).                                                   
- A client cannot buy the same product more than one time.                                            -Done!
- The clients should not be able to buy a product more times than the quantity in the store           
unless a product is returned or added by the administrator (owner)                                    -Done!
- Everyone should be able to see the addresses of all clients that have ever bought a given product.  -Done!
*/

error SimpleStore__AlreadyBoughtThatItem();
error SimpleStore__PriceTooLow();

/**
 * @title LimeStore - a simple web3 store
 * @author Ned S.
 * @notice Simple web3 store implementation 
    with basic add/update product nomenclature 
    and basic client purchase/return/list functionality
 * @dev This contract is not a final product
 * @custom:experimental This is an experimental contract.
 */
contract SimpleStore is ReentrancyGuard {
    struct Owners {
        // owner address -> block of purchase
        mapping(address => uint256) ownerAndBlockOfPurchase;
        address[] ownerAddresses;
        uint256 numberOfOwners;
    }

    // ProductId -> Owners
    mapping(uint256 => Owners) private s_productOwners;

    // Variable that maintains the maximum products per order
    uint256 private productsPerOrder = 1;
    // Variable that maintains owner address
    address private s_owner;
    // Variable that maintains product contract address
    address private s_productAddress;
    // Variable that maintains the product price
    uint256 private s_productPrice = 10000000000000000; // 0.01 ether per product

    // Sets the original owner of
    // contract when it is deployed.
    constructor(address productAddress) {
        s_owner = msg.sender;
        s_productAddress = productAddress;
    }

    function buyProduct(uint256 productId) public payable {
        if (msg.value < s_productPrice) {
            revert SimpleStore__PriceTooLow();
        }

        if (s_productOwners[productId].ownerAndBlockOfPurchase[msg.sender] != 0) {
            revert SimpleStore__AlreadyBoughtThatItem();
        }
        bytes memory data;
        IERC1155(s_productAddress).safeTransferFrom(
            s_owner,
            msg.sender,
            productId,
            productsPerOrder,
            data
        );
        s_productOwners[productId].ownerAndBlockOfPurchase[msg.sender] = block.number;
        s_productOwners[productId].ownerAddresses.push(msg.sender);
        s_productOwners[productId].numberOfOwners += 1;
    }

    function showProducts() public view returns (uint256[] memory) {
        // Product contract
        Product product = Product(s_productAddress);
        return product.getUniqueProductsIds();
    }

    function showOwners(uint256 productId) public view returns (address[] memory) {
        address[] memory owners = new address[](s_productOwners[productId].numberOfOwners);
        for (uint256 i = 0; i < s_productOwners[productId].numberOfOwners; i++) {
            owners[i] = s_productOwners[productId].ownerAddresses[i];
        }

        return owners;
    }
}
