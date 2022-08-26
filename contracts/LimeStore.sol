// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/** 
Using Remix develop a contract for a TechnoLime Store.

- The administrator (owner) of the store should be able to add new products and the quantity of them. 
- The administrator should not be able to add the same product twice, just quantity.                  
- Buyers (clients) should be able to see the available products and buy them by their id.             
- Buyers should be able to return products if they are not satisfied
(within a certain period in blocktime: 100 blocks).                                                   
- A client cannot buy the same product more than one time.                                            
- The clients should not be able to buy a product more times than the quantity in the store
unless a product is returned or added by the administrator (owner)                                    
- Everyone should be able to see the addresses of all clients that have ever bought a given product.  
*/

error LimeStore__NotOwner();
error LimeStore__ZeroIsNotAllowedForProductId();
error LimeStore__AlreadyBoughtThatItem();
error LimeStore__OutOfStock();
error LimeStore__HundredBlocksHavePassedSincePurchase();
error LimeStore__UserHasNoPurchases();

/**
 * @title LimeStore - a simple web3 store
 * @author Ned S.
 * @notice Simple web3 store implementation 
    with basic add/update product nomenclature 
    and basic client purchase/return/list functionality
 * @dev This contract is not a final product
 * @custom:experimental This is an experimental contract.
 */
contract LimeStore {
    // Product quantity available for purcahse used for invoice and event
    // Client cannot buy more than 1 item
    uint256 constant c_quantytyPerPurchase = 1;

    // Event for listing new or updating existing product
    event ItemListed(
        uint256 indexed productId,
        string indexed productName,
        uint256 indexed quantity,
        uint256 unitPrice
    );

    // Event for purchase of product
    event ItemBought(
        uint256 indexed productId,
        address indexed buyer,
        uint256 indexed blockNumber
    );

    // Variable that maintains owner address
    address private s_owner;

    // Product object
    struct Product {
        string name;
        uint256 quantity;
        uint256 unitPrice;
    }

    // Map that maintains current nomenclature of products.
    mapping(uint256 => Product) public s_products; // productId => Product

    // Map that contains purchased items, their owners and time of purchase
    mapping(uint256 => mapping(address => uint256)) s_invoices; // productId => owner - block number

    // Array that holds each unique owner of product (regardless how many products he owns)
    address[] s_clients;

    // Map used to filter owners of more than one product
    mapping(address => bool) s_clientExist;

    // Sets the original owner of
    // contract when it is deployed.
    constructor() {
        s_owner = msg.sender;
    }

    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not!
    modifier onlyOwner() {
        // Using if statement instead of require because its optimal ?
        if (!isOwner()) {
            revert LimeStore__NotOwner();
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
     * @notice Method for adding products to the shop
     * @param productId - the id of the new product
     * @param quantity - the quantity of the new product
     * @param unitPrice - the price of the new product
     * @dev Update products by adding existing Id
     * @dev ItemListed event is fired after each add/update
     * @dev The onlyOwner modifier used here prevents 
        this function to be called by people other 
        than owner who deployed it.
     */
    function addOrUpdateProduct(
        uint256 productId,
        string memory productName,
        uint256 quantity,
        uint256 unitPrice
    ) external onlyOwner {
        if (productId == 0) {
            revert LimeStore__ZeroIsNotAllowedForProductId();
        }

        s_products[productId].name = productName;
        s_products[productId].quantity = quantity;
        s_products[productId].unitPrice = unitPrice;
        emit ItemListed(productId, productName, quantity, unitPrice);
    }

    /**
     * @notice Method for buying listed products
     * @param productId - the id of the product for purchase
     * @dev Revert with error if product quantity is 0
     * @dev Revert with error if msg.sender already has that item
     */
    function buyItem(uint256 productId) public payable {
        // Check if item has quantity, revert if none (=0)
        if (s_products[productId].quantity == 0) {
            revert LimeStore__OutOfStock();
        }

        // Check if that item was bought by this client, revert if true
        if (s_invoices[productId][msg.sender] > 0) {
            revert LimeStore__AlreadyBoughtThatItem();
        }

        s_products[productId].quantity -= c_quantytyPerPurchase;
        s_invoices[productId][msg.sender] = block.number;

        // Hold list of unique buyers
        if (!s_clientExist[msg.sender]) {
            s_clientExist[msg.sender] = true;
            s_clients.push(msg.sender);
        }
        emit ItemBought(productId, msg.sender, block.number);
    }

    /**
     * @notice Method for listing owners of provided product (id)
     * @param productId - the id of the product for check
     * @dev Revert with error if product quantity is 0
     * @dev Can this be improvet to work with one loop ?
     */
    function showProductOwners(uint256 productId)
        public
        view
        returns (address[] memory)
    {
        // Product id 0 is not allowed
        if (productId == 0) {
            revert LimeStore__ZeroIsNotAllowedForProductId();
        }

        // First loop is used to filter the addresses that own that product
        uint productOwnersLength = 0;
        address[] memory productOwners = new address[](s_clients.length);
        for (uint i = 0; i < s_clients.length; i++) {
            // If blocknumber is present client has bought that item
            if (s_invoices[productId][s_clients[i]] > 0) {
                productOwners[i] = s_clients[i];
                productOwnersLength++;
            }
        }

        // Second loop is used to remove blank spaces returned from first array
        uint resultLength = 0;
        address[] memory result = new address[](productOwnersLength);
        for (uint i = 0; i < productOwners.length; i++) {
            if (productOwners[i] == address(0x0)) {
                continue;
            } else {
                result[resultLength] = productOwners[i];
                resultLength++;
            }
        }

        return result;
    }

    /**
     * @notice Method for returning product if clien is not satisfied
     * @param productId - the id of the product for return
     * @dev Revert with error if product quantity is 0
     * @dev Can this be improvet to work with one loop ?
     */
    function returnProduct(uint256 productId) public returns (bool success) {
        uint256 productBlock = s_invoices[productId][msg.sender];
        uint256 currentBlock = block.number;

        // If block is 0 current client has no purchases of the product
        if (productBlock != 0) {
            // Should be 100 but for the sake of debugging was used lower value
            if ((currentBlock - productBlock) > 3) {
                revert LimeStore__HundredBlocksHavePassedSincePurchase();
            }
        } else {
            revert LimeStore__UserHasNoPurchases();
        }

        delete s_invoices[productId][msg.sender];
        s_products[productId].quantity += c_quantytyPerPurchase;

        success = true;
        return success;
    }

    /**
TODO
Implement Multicall contract ?
Implement shop as EIP-1175 ?
Implement product object as ERC20 token ?
Optimize the mapping for clients, remove clients after return.
Improve the showing of products when listed.
Refactor the whole contract to optimize gas costs?
Implement the project on hardhat for local development!
Implement deployment and utility (for parsing the product price) scripts!
Write tests!
Deploy the contract on Rinkeby test network ?
Add user friendly front-end using ethers.js and next.js ?
     */
}
