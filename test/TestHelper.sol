// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {
    IAccessControlUpgradeable,
    IAccessControlEnumerableUpgradeable
} from "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
} from "openzeppelin-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable
} from "openzeppelin-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

import {IERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";

import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import {
    IONFT721Upgradeable,
    IONFT721CoreUpgradeable
} from "solidity-examples/contracts/contracts-upgradable/token/ONFT721/IONFT721Upgradeable.sol";

import {
    OperatorFilterRegistry,
    OperatorFilterRegistryErrorsAndEvents
} from "operator-filter-registry/src/OperatorFilterRegistry.sol";

import {LZEndpointMock} from "./mocks/LZEndpointMock.sol";

import {
    PendingOwnableUpgradeable,
    IPendingOwnableUpgradeable,
    IERC165Upgradeable
} from "src/utils/PendingOwnableUpgradeable.sol";
import {
    SafeAccessControlEnumerableUpgradeable,
    ISafeAccessControlEnumerableUpgradeable
} from "src/utils/SafeAccessControlEnumerableUpgradeable.sol";
import {SafePausableUpgradeable, ISafePausableUpgradeable} from "src/utils/SafePausableUpgradeable.sol";

import {OZNFTBaseUpgradeable, IOZNFTBaseUpgradeable} from "src/OZNFTBaseUpgradeable.sol";
import {ERC721ABaseUpgradeable, IERC721ABaseUpgradeable} from "src/ERC721ABaseUpgradeable.sol";
import {ERC1155BaseUpgradeable, IERC1155BaseUpgradeable} from "src/ERC1155BaseUpgradeable.sol";

import {NFTBaseUpgradeable, INFTBaseUpgradeable} from "src/NFTBaseUpgradeable.sol";

abstract contract TestHelper is Test {
    address payable internal joepegs = payable(makeAddr("joepegs"));

    OZNFTBaseUpgradeableHarness ozNftBase;
    ERC721ABaseUpgradeableHarness erc721aBase;
    ERC1155BaseUpgradeableHarness erc1155Base;

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

contract OZNFTBaseUpgradeableHarness is OZNFTBaseUpgradeable {
    function initialize(address lzEndpoint, address dummyAddress) external initializer {
        __OZNFTBase_init("OZNFT Base Upgradeable Harness", "OBUH", lzEndpoint, 500, dummyAddress, dummyAddress);
    }

    function initialize(address dummyAddress) external initializer {
        __OZNFTBase_init("OZNFT Base Upgradeable Harness", "OBUH", dummyAddress, 500, dummyAddress, dummyAddress);
    }

    function wrongInitialize(address dummyAddress) external {
        __OZNFTBase_init("OZNFT Base Upgradeable Harness", "OBUH", dummyAddress, 500, dummyAddress, dummyAddress);
    }

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}

contract ERC721ABaseUpgradeableHarness is ERC721ABaseUpgradeable {
    function initialize(address dummyAddress) external initializer initializerERC721A {
        __ERC721ABase_init("ERC721A Base Upgradeable Harness", "EBUH", 500, dummyAddress, dummyAddress);
    }

    function wrongInitialize(address dummyAddress) external {
        __ERC721ABase_init("ERC721A Base Upgradeable Harness", "EBUH", 500, dummyAddress, dummyAddress);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract ERC1155BaseUpgradeableHarness is ERC1155BaseUpgradeable {
    function initialize(address dummyAddress) external initializer {
        __ERC1155Base_init(
            "ipfs://{cid}/{id}", "1155 Base Upgradeable Harness", "1155EBUH", 500, dummyAddress, dummyAddress
        );
    }

    function wrongInitialize(address dummyAddress) external {
        __ERC1155Base_init(
            "ipfs://{cid}/{id}", "1155 Base Upgradeable Harness", "1155EBUH", 500, dummyAddress, dummyAddress
        );
    }

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId, 1, "");
    }
}
