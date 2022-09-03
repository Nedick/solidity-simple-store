// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

error Product__NotOwnerOfContract();

contract Product is ERC1155 {
    // Variable that maintains owner address
    address private immutable s_owner;
    // Variable that maintains token URI
    string private s_tokenUri;
    // itemId -> true
    mapping(uint256 => bool) private s_uniqueProducts;
    uint256[] private s_productIds;

    constructor(string memory _uri) ERC1155(_uri) {
        s_tokenUri = _uri;
        s_owner = msg.sender;
    }

    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not!
    modifier onlyOwner() {
        // Using if statement instead of require because its optimal ?
        if (!isOwner()) {
            revert Product__NotOwnerOfContract();
        }
        _;
    }

    /**
     * @notice Method for owners to verify their ownership
     * @return true for owners otherwise false
     */
    function isOwner() public view returns (bool) {
        return msg.sender == s_owner;
    }

    /**
     * @notice Method for adding product to the marketplace
     * @param amount - amount of tokens to add
     * @param itemId - id of the product to add additional quantities to (can start from 0)
     * @dev If existing itemId is provided the amount will be added to the total quantity
     */
    function addProduct(uint256 itemId, uint256 amount) public onlyOwner {
        bytes memory data;
        if (!s_uniqueProducts[itemId]) {
            s_uniqueProducts[itemId] = true;
            s_productIds.push(itemId);
        }
        _mint(msg.sender, itemId, amount, data);
    }

    /**
     * @notice Method for retrieving Id's of all products
     * @return uint256 array
     */
    function getUniqueProductsIds() public view returns (uint256[] memory) {
        return s_productIds;
    }
}
