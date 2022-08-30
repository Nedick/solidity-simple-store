// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error Product__NotOwnerOfContract();
error Product__NotOwnerOfThisNft();

contract Product is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    // Variable that maintains owner address
    address private s_owner;
    string tokenUri;

    constructor(string memory _uri) ERC1155(_uri) {
        tokenUri = _uri;
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
     * @param itemId - id of the product to add additional quantities to
     * @param amount - amount of tokens to add
     * @dev If existing item id is provided then the quantity of the product is updated by the amount supplied
     */
    function mint(uint256 itemId, uint256 amount) public onlyOwner {
        bytes memory data;
        _mint(msg.sender, itemId, amount, data);
    }

    /**
     * @notice Method for burning returned products
     * @param account - the account to burn the tokens from
     * @param tokenId - Id of the token
     * @dev Param amount is commented out because it is not used in the current implementation
     * @dev Token amount is hardcoded to 1 because clients can hold only 1 of each product
     * @dev Call parent contract burn method directly with super.
     */
    function burn(
        address account,
        uint256 tokenId /* uint256 amount */
    ) public {
        super._burn(account, tokenId, 1);
    }
}
