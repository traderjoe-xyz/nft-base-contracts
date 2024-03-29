// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ONFT721Upgradeable} from "./layerZero/ONFT721Upgradeable.sol";
import {ILayerZeroEndpointUpgradeable} from "./layerZero/LzAppUpgradeable.sol";
import {ERC721Upgradeable, IERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {NFTBaseUpgradeable} from "./NFTBaseUpgradeable.sol";
import {IOZNFTBaseUpgradeable} from "./interfaces/IOZNFTBaseUpgradeable.sol";

abstract contract OZNFTBaseUpgradeable is NFTBaseUpgradeable, ONFT721Upgradeable, IOZNFTBaseUpgradeable {
    /**
     * @notice Token URI after collection reveal
     */
    string public override baseURI;

    /**
     * @notice Token URI before the collection reveal
     */
    string public override unrevealedURI;

    function __OZNFTBase_init(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        uint256 _joeFeePercent,
        address _joeFeeCollector,
        address royaltyReceiver
    ) internal onlyInitializing {
        __ONFT721Upgradeable_init(_name, _symbol, _lzEndpoint);
        __NFTBase_init(_joeFeePercent, _joeFeeCollector, royaltyReceiver);

        __OZNFTBase_init_unchained();
    }

    function __OZNFTBase_init_unchained() internal onlyInitializing {}

    /**
     * @notice Set the base URI
     * @dev This sets the URI for revealed tokens
     * @param _baseURI Base URI to be set
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(baseURI);
    }

    /**
     * @notice Set the unrevealed URI
     * @dev This sets the URI for unrevealed tokens
     * @param _unrevealedURI Unrevealed URI to be set
     */
    function setUnrevealedURI(string calldata _unrevealedURI) external override onlyOwner {
        unrevealedURI = _unrevealedURI;
        emit UnrevealedURISet(unrevealedURI);
    }

    /**
     * @notice Set LayerZeroEndpoint address
     * @param _endpoint address of LayerZeroEndpoint to set
     */
    function setLzEndpoint(address _endpoint) external override onlyOwner {
        if (_endpoint == address(0)) {
            revert OZNFTBaseUpgradeable__InvalidAddress();
        }

        lzEndpoint = ILayerZeroEndpointUpgradeable(_endpoint);
        emit LZEndpointSet(_endpoint);
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
        override(NFTBaseUpgradeable, ONFT721Upgradeable, IOZNFTBaseUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IOZNFTBaseUpgradeable).interfaceId
            || NFTBaseUpgradeable.supportsInterface(interfaceId) || ONFT721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev `aprove` wrapper to prevent the sender to approve a non-allowed operator
     * @param operator Address being approved
     * @param tokenId TokenID approved
     */
    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev `aproveForAll` wrapper to prevent the sender to approve a non-allowed operator
     * @param operator Address being approved
     * @param approved Approval status
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev `transferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId TokenID to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId TokenID to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param tokenId TokenID to transfer
     * @param data Data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
