// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC1155Upgradeable, IERC165Upgradeable} from "openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import {INFTBaseUpgradeable} from "./INFTBaseUpgradeable.sol";

interface IERC1155BaseUpgradeable is INFTBaseUpgradeable, IERC1155Upgradeable {
    event URISet(string uri);

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(INFTBaseUpgradeable, IERC165Upgradeable)
        returns (bool);
}
