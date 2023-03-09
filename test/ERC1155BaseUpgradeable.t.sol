// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

import {IERC1155Upgradeable} from "openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import {IERC1155MetadataURIUpgradeable} from
    "openzeppelin-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

import {ERC1155BaseUpgradeable, IERC1155BaseUpgradeable} from "src/upgradeables/ERC1155BaseUpgradeable.sol";
import {INFTBaseUpgradeable} from "src/upgradeables/interfaces/INFTBaseUpgradeable.sol";
import {IPendingOwnableUpgradeable} from "src/upgradeables/interfaces/utils/IPendingOwnableUpgradeable.sol";

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
}

contract ERC1155BaseUpgradeableTest is TestHelper {
    event URISet(string uri);

    ERC1155BaseUpgradeableHarness erc1155Base;

    function setUp() public {
        erc1155Base = new ERC1155BaseUpgradeableHarness();
        erc1155Base.initialize(joepegs);

        erc1155Base.setWithdrawAVAXStartTime(100);
        vm.warp(100);
    }

    function test_Initialize(address joeFeeReceiver) public {
        vm.assume(joeFeeReceiver != address(0));
        erc1155Base = new ERC1155BaseUpgradeableHarness();
        erc1155Base.initialize(joeFeeReceiver);

        assertEq(erc1155Base.owner(), address(this), "test_Initialize::1");
        assertEq(erc1155Base.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");

        assertEq(
            address(erc1155Base.operatorFilterRegistry()),
            0x000000000000AAeB6D7670E522A718067333cd4E,
            "test_Initialize::3"
        );

        assertEq(erc1155Base.joeFeePercent(), 500, "test_Initialize::4");
        assertEq(erc1155Base.joeFeeCollector(), joeFeeReceiver, "test_Initialize::5");

        (address royaltiesReceiver, uint256 royaltiesPercent) = erc1155Base.royaltyInfo(0, 10_000);
        assertEq(royaltiesReceiver, joeFeeReceiver, "test_Initialize::6");
        assertEq(royaltiesPercent, 500, "test_Initialize::7");

        assertEq(erc1155Base.name(), "1155 Base Upgradeable Harness", "test_Initialize::8");
        assertEq(erc1155Base.symbol(), "1155EBUH", "test_Initialize::9");
        assertEq(erc1155Base.uri(0), "ipfs://{cid}/{id}", "test_Initialize::10");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        erc1155Base.initialize(joepegs);
    }

    function test_Revert_WrongInitializeImplementation() public {
        erc1155Base = new ERC1155BaseUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        erc1155Base.wrongInitialize(joepegs);
    }

    function test_SetURI(string memory newURI) public {
        vm.expectEmit(true, true, true, true);
        emit URISet(newURI);
        erc1155Base.setURI(newURI);

        assertEq(erc1155Base.uri(0), newURI, "test_SetURI::1");
    }

    function test_Revert_SetURIWhenNotOwner(address alice, string memory newURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        erc1155Base.setURI(newURI);
    }

    function test_SupportInterface() public {
        assertTrue(erc1155Base.supportsInterface(type(IERC1155BaseUpgradeable).interfaceId), "test_SupportInterface::1");
        assertTrue(erc1155Base.supportsInterface(type(IERC1155Upgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(
            erc1155Base.supportsInterface(type(IERC1155MetadataURIUpgradeable).interfaceId), "test_SupportInterface::2"
        );
        assertTrue(erc1155Base.supportsInterface(type(INFTBaseUpgradeable).interfaceId), "test_SupportInterface::3");
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != 0x45aea0ae && interfaceId != 0x01ffc9a7 && interfaceId != 0x5a05180f
                && interfaceId != 0x7965db0b && interfaceId != 0x7260a8cd && interfaceId != 0x2a55205a
                && interfaceId != type(INFTBaseUpgradeable).interfaceId
                && interfaceId != type(IERC1155Upgradeable).interfaceId
                && interfaceId != type(IERC1155MetadataURIUpgradeable).interfaceId
                && interfaceId != type(IERC1155BaseUpgradeable).interfaceId
        );

        assertFalse(erc1155Base.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
