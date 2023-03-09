// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

import {
    OperatorFilterRegistry,
    OperatorFilterRegistryErrorsAndEvents,
    IOperatorFilterRegistry
} from "operator-filter-registry/src/OperatorFilterRegistry.sol";

import {ERC721ABaseUpgradeable, IERC721ABaseUpgradeable} from "src/upgradeables/ERC721ABaseUpgradeable.sol";
import {ERC1155BaseUpgradeable, IERC1155BaseUpgradeable} from "src/upgradeables/ERC1155BaseUpgradeable.sol";
import {OZNFTBaseUpgradeable, IOZNFTBaseUpgradeable} from "src/upgradeables/OZNFTBaseUpgradeable.sol";

contract OZNFTBaseUpgradeableHarness is OZNFTBaseUpgradeable {
    function initialize(address dummyAddress) external initializer {
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

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId, 1, "");
    }
}

contract OperatorRegistryTest is TestHelper {
    address constant DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    OperatorFilterRegistry constant registry = OperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    OZNFTBaseUpgradeableHarness ozNftBase;
    ERC721ABaseUpgradeableHarness erc721aBase;
    ERC1155BaseUpgradeableHarness erc1155Base;

    address blockedAddress = makeAddr("blocked");
    uint256 tokenIdTransfered = 49;

    function setUp() public {
        vm.createSelectFork(StdChains.getChain("avalanche").rpcUrl, 27218980);

        ozNftBase = new OZNFTBaseUpgradeableHarness();
        ozNftBase.initialize(joepegs);

        erc721aBase = new ERC721ABaseUpgradeableHarness();
        erc721aBase.initialize(joepegs);

        erc1155Base = new ERC1155BaseUpgradeableHarness();
        erc1155Base.initialize(joepegs);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(DEFAULT_SUBSCRIPTION, blockedAddress, true);

        ozNftBase.mint(tokenIdTransfered);
        erc721aBase.mint(100);
        erc1155Base.mint(tokenIdTransfered);
    }

    function test_Revert_TransferFromBlockedOperator(address alice) public {
        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.transferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.transferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.safeTransferFrom(address(this), alice, tokenIdTransfered, 1, "");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenIdTransfered;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.safeBatchTransferFrom(address(this), alice, tokenIds, amounts, "");
    }

    function test_Revert_ApprovalToBlockedOperator() public {
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.approve(blockedAddress, tokenIdTransfered);

        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.approve(blockedAddress, tokenIdTransfered);

        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.setApprovalForAll(blockedAddress, true);
    }

    function test_ApproveAfterFilterRegistryHasBeenDeactivated() public {
        ozNftBase.setOperatorFilterRegistryAddress(address(0));
        ozNftBase.approve(blockedAddress, tokenIdTransfered);

        erc721aBase.setOperatorFilterRegistryAddress(address(0));
        erc721aBase.approve(blockedAddress, tokenIdTransfered);

        erc1155Base.setOperatorFilterRegistryAddress(address(0));
        erc1155Base.setApprovalForAll(blockedAddress, true);
    }
}
