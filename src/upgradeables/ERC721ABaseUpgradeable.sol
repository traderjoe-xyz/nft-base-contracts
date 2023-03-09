// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721AUpgradeable, IERC721AUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";

import {NFTBaseUpgradeable} from "./NFTBaseUpgradeable.sol";
import {IERC721ABaseUpgradeable} from "./interfaces/IERC721ABaseUpgradeable.sol";

contract ERC721ABaseUpgradeable is NFTBaseUpgradeable, ERC721AUpgradeable, IERC721ABaseUpgradeable {
    /// @notice Token URI after collection reveal
    string public override baseURI;

    /// @notice Token URI before the collection reveal
    string public override unrevealedURI;

    function __ERC721ABase_init(
        string memory _name,
        string memory _symbol,
        uint256 _joeFeePercent,
        address _joeFeeCollector,
        address royaltyReceiver
    ) internal onlyInitializing onlyInitializingERC721A {
        __ERC721A_init(_name, _symbol);
        __NFTBase_init(_joeFeePercent, _joeFeeCollector, royaltyReceiver);

        __ERC721ABase_init_unchained();
    }

    function __ERC721ABase_init_unchained() internal onlyInitializing onlyInitializingERC721A {}

    /// @notice Set the base URI
    /// @dev This sets the URI for revealed tokens
    /// @param _baseURI Base URI to be set
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(baseURI);
    }

    /// @notice Set the unrevealed URI
    /// @dev This sets the URI for unrevealed tokens
    /// @param _unrevealedURI Unrevealed URI to be set
    function setUnrevealedURI(string calldata _unrevealedURI) external override onlyOwner {
        unrevealedURI = _unrevealedURI;
        emit UnrevealedURISet(unrevealedURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(NFTBaseUpgradeable, ERC721AUpgradeable, IERC721ABaseUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC721ABaseUpgradeable).interfaceId
            || interfaceId == type(IERC721AUpgradeable).interfaceId || NFTBaseUpgradeable.supportsInterface(interfaceId)
            || ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev `aprove` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param tokenId TokenID approved
    function approve(address operator, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev `aproveForAll` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param approved Approval status
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev `transferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    /// @param data Data to send along with a safe transfer check
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
