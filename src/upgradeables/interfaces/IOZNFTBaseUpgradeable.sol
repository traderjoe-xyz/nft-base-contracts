// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IONFT721Upgradeable,
    IERC165Upgradeable
} from "solidity-examples-upgradeable/token/ONFT721/IONFT721Upgradeable.sol";

import {INFTBaseUpgradeable} from "./INFTBaseUpgradeable.sol";

interface IOZNFTBaseUpgradeable is INFTBaseUpgradeable, IONFT721Upgradeable {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function setBaseURI(string calldata baseURI) external;

    function setUnrevealedURI(string calldata baseURI) external;

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(INFTBaseUpgradeable, IERC165Upgradeable)
        returns (bool);
}
