// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {OZNFTBaseUpgradeable, IOZNFTBaseUpgradeable} from "src/upgradeables/OZNFTBaseUpgradeable.sol";
import {ERC721ABaseUpgradeable, IERC721ABaseUpgradeable} from "src/upgradeables/ERC721ABaseUpgradeable.sol";
import {ERC1155BaseUpgradeable, IERC1155BaseUpgradeable} from "src/upgradeables/ERC1155BaseUpgradeable.sol";

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
