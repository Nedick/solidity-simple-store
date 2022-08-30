// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error SimpleStore__NotOwner();
error SimpleStore__ZeroIsNotAllowedForProductQuantity();
error SimpleStore__AlreadyBoughtThatItem();
error SimpleStore__OutOfStock();
error SimpleStore__HundredBlocksHavePassedSincePurchase();
error SimpleStore__UserHasNoPurchases();

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
    // Seller address -> productIds
    mapping(address => uint256) private s_products;

    // Variable that maintains owner address
    address private s_owner;

    // Sets the original owner of
    // contract when it is deployed.
    constructor() {
        s_owner = msg.sender;
    }
}
