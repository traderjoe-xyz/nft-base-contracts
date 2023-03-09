// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1155Upgradeable, IERC1155Upgradeable} from "openzeppelin-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

import {NFTBaseUpgradeable, INFTBaseUpgradeable} from "./NFTBaseUpgradeable.sol";
import {IERC1155BaseUpgradeable, IERC165Upgradeable} from "./interfaces/IERC1155BaseUpgradeable.sol";

contract ERC1155BaseUpgradeable is NFTBaseUpgradeable, ERC1155Upgradeable, IERC1155BaseUpgradeable {
    /**
     * @notice Name of the NFT collection
     */
    string public name;

    /**
     * @notice Symbol of the NFT collection
     */
    string public symbol;

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

    /// @notice Set the base URI for all tokens
    /// @param newURI Base URI to be set
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
        emit URISet(newURI);
    }

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

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
