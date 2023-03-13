// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";

import {INFTBaseUpgradeable} from "./INFTBaseUpgradeable.sol";

interface IERC721ABaseUpgradeable is INFTBaseUpgradeable, IERC721AUpgradeable {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function setBaseURI(string calldata baseURI) external;

    function setUnrevealedURI(string calldata baseURI) external;

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(INFTBaseUpgradeable, IERC721AUpgradeable)
        returns (bool);
}
