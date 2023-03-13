// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1155Upgradeable, IERC1155Upgradeable} from "openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import {NFTBaseUpgradeable} from "./NFTBaseUpgradeable.sol";
import {IERC1155BaseUpgradeable} from "./interfaces/IERC1155BaseUpgradeable.sol";

abstract contract ERC1155BaseUpgradeable is NFTBaseUpgradeable, ERC1155Upgradeable, IERC1155BaseUpgradeable {
    /**
     * @notice Name of the NFT collection
     */
    string public override name;

    /**
     * @notice Symbol of the NFT collection
     */
    string public override symbol;

    function __ERC1155Base_init(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        uint256 _joeFeePercent,
        address _joeFeeCollector,
        address royaltyReceiver
    ) internal onlyInitializing {
        __NFTBase_init(_joeFeePercent, _joeFeeCollector, royaltyReceiver);
        __ERC1155_init(_uri);

        __ERC1155Base_init_unchained(_name, _symbol);
    }

    function __ERC1155Base_init_unchained(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Set the base URI for all tokens
     * @param newURI Base URI to be set
     */
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
        emit URISet(newURI);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(NFTBaseUpgradeable, ERC1155Upgradeable, IERC1155BaseUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC1155BaseUpgradeable).interfaceId
            || ERC1155Upgradeable.supportsInterface(interfaceId) || NFTBaseUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev `setApprovalForAll` wrapper to prevent the sender to approve a non-allowed operator
     * @param operator Address being approved
     * @param approved Approval status
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param id TokenID to transfer
     * @param amount Amount to transfer
     * @param data Data to pass to receiver
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev `safeBatchTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param ids TokenIDs to transfer
     * @param amounts Amounts to transfer
     * @param data Data to pass to receiver
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
