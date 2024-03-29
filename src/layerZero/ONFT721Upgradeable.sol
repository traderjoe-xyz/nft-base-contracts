// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {IONFT721Upgradeable} from
    "solidity-examples/contracts/contracts-upgradable/token/ONFT721/IONFT721Upgradeable.sol";

import {ONFT721CoreUpgradeable} from "./ONFT721CoreUpgradeable.sol";

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
abstract contract ONFT721Upgradeable is ONFT721CoreUpgradeable, ERC721Upgradeable, IONFT721Upgradeable {
    function __ONFT721Upgradeable_init(string memory _name, string memory _symbol, address _lzEndpoint)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(_name, _symbol);
        __ONFT721CoreUpgradeable_init_unchained(_lzEndpoint);
    }

    function __ONFT721Upgradeable_init_unchained(string memory _name, string memory _symbol, address _lzEndpoint)
        internal
        onlyInitializing
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ONFT721CoreUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IONFT721Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _debitFrom(address _from, uint16, bytes memory, uint256 _tokenId) internal virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ONFT721: send caller is not owner nor approved");
        require(ERC721Upgradeable.ownerOf(_tokenId) == _from, "ONFT721: send from incorrect owner");
        _transfer(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint256 _tokenId) internal virtual override {
        require(!_exists(_tokenId) || (_exists(_tokenId) && ERC721Upgradeable.ownerOf(_tokenId) == address(this)));
        if (!_exists(_tokenId)) {
            _safeMint(_toAddress, _tokenId);
        } else {
            _transfer(address(this), _toAddress, _tokenId);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
