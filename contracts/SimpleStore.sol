// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Product.sol";

error SimpleStore__AlreadyBoughtThatItem();
error SimpleStore__PriceTooLow();
error SimpleStore__NotAvailableForReturn();

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

    // Sets the original owner of the shop and product contract when it is deployed.
    constructor(address productAddress) {
        s_owner = msg.sender;
        s_productAddress = productAddress;
    }

    /**
     * @notice Method for product purchase
     * @param productId - Id of the token for purchase
     */
    function buyProduct(uint256 productId) public payable {
        // Revert if supplied price is not exactly 0.01 ether (each product price)
        if (msg.value < s_productPrice) {
            revert SimpleStore__PriceTooLow();
        }

        // If there is block number clien has already purchased this item
        if (s_productOwners[productId].ownerAndBlockOfPurchase[msg.sender] != 0) {
            revert SimpleStore__AlreadyBoughtThatItem();
        }

        // empty data needed to comply with safeTransferFrom param count
        bytes memory data;
        // Transfer the tokens to the new owner
        IERC1155(s_productAddress).safeTransferFrom(
            s_owner,
            msg.sender,
            productId,
            productsPerOrder,
            data
        );
        // Give aproval to the new owner to allow return of product if needed
        IERC1155(s_productAddress).setApprovalForAll(msg.sender, true);
        // Update product ownership
        s_productOwners[productId].ownerAndBlockOfPurchase[msg.sender] = block.number;
        s_productOwners[productId].ownerAddresses.push(msg.sender);
        s_productOwners[productId].numberOfOwners += 1;
    }

    /**
     * @notice Method for displaying all owners of
     * @param productId - Id of the token for return
     */
    function returnProduct(uint256 productId) public {
        // revert if 100 blocks have passed since purchase
        if ((s_productOwners[productId].ownerAndBlockOfPurchase[msg.sender] + 100) < block.number) {
            revert SimpleStore__NotAvailableForReturn();
        }

        // empty data needed to comply with safeTransferFrom param count
        bytes memory data;
        // Return the tokens to the old owner
        IERC1155(s_productAddress).safeTransferFrom(
            msg.sender,
            s_owner,
            productId,
            productsPerOrder,
            data
        );
    }

    /**
     * @notice Method for displaying all owners of
     * @param productId - Id of the token for ownership review
     * @return array with all clients that have purchased the supplied product
     */
    function showOwners(uint256 productId) public view returns (address[] memory) {
        address[] memory owners = new address[](s_productOwners[productId].numberOfOwners);
        for (uint256 i = 0; i < s_productOwners[productId].numberOfOwners; i++) {
            owners[i] = s_productOwners[productId].ownerAddresses[i];
        }

        return owners;
    }

    /**
     * @notice Method for displaying the available products for purchase
     * @return array with all available product id's
     */
    function showProducts() public view returns (uint256[] memory) {
        // Product contract
        return Product(s_productAddress).getUniqueProductsIds();
    }
}
