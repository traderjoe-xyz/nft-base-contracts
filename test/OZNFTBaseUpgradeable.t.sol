// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

import {
    IONFT721Upgradeable,
    IONFT721CoreUpgradeable
} from "solidity-examples-upgradeable/token/ONFT721/IONFT721Upgradeable.sol";
import {IERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from
    "openzeppelin-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import {INFTBaseUpgradeable} from "src/upgradeables/interfaces/INFTBaseUpgradeable.sol";
import {IPendingOwnableUpgradeable} from "src/upgradeables/interfaces/utils/IPendingOwnableUpgradeable.sol";

contract OZNFTBaseUpgradeableTest is TestHelper {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

    function setUp() public {
        ozNftBase = new OZNFTBaseUpgradeableHarness();
        ozNftBase.initialize(joepegs);
    }

    function test_Initialize(address dummyAddress) public {
        vm.assume(dummyAddress != address(0));
        ozNftBase = new OZNFTBaseUpgradeableHarness();
        ozNftBase.initialize(dummyAddress);

        assertEq(ozNftBase.owner(), address(this), "test_Initialize::1");
        assertEq(ozNftBase.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");

        assertEq(
            address(ozNftBase.operatorFilterRegistry()),
            0x000000000000AAeB6D7670E522A718067333cd4E,
            "test_Initialize::3"
        );

        assertEq(ozNftBase.joeFeePercent(), 500, "test_Initialize::4");
        assertEq(ozNftBase.joeFeeCollector(), dummyAddress, "test_Initialize::5");

        (address royaltiesReceiver, uint256 royaltiesPercent) = ozNftBase.royaltyInfo(0, 10_000);
        assertEq(royaltiesReceiver, dummyAddress, "test_Initialize::6");
        assertEq(royaltiesPercent, 500, "test_Initialize::7");

        assertEq(address(ozNftBase.lzEndpoint()), dummyAddress, "test_Initialize::8");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        ozNftBase.initialize(joepegs);
    }

    function test_Revert_WrongInitializeImplementation() public {
        ozNftBase = new OZNFTBaseUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        ozNftBase.wrongInitialize(joepegs);
    }

    function test_SetBaseURI(string memory baseURI) public {
        vm.expectEmit(true, true, true, false);
        emit BaseURISet(baseURI);
        ozNftBase.setBaseURI(baseURI);

        assertEq(ozNftBase.baseURI(), baseURI, "test_SetBaseURI::1");
    }

    function test_Revert_SetBaseURIWhenNotOwner(address alice, string memory baseURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        ozNftBase.setBaseURI(baseURI);
    }

    function test_SetUnrevealedURI(string memory unrevealedURI) public {
        vm.expectEmit(true, true, true, false);
        emit UnrevealedURISet(unrevealedURI);
        ozNftBase.setUnrevealedURI(unrevealedURI);

        assertEq(ozNftBase.unrevealedURI(), unrevealedURI, "test_SetUnrevealedURI::1");
    }

    function test_Revert_SetUnrevealedURIWhenNotOwner(address alice, string memory unrevealedURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        ozNftBase.setUnrevealedURI(unrevealedURI);
    }

    function test_SupportInterface() public {
        assertTrue(ozNftBase.supportsInterface(type(IOZNFTBaseUpgradeable).interfaceId), "test_SupportInterface::1");
        assertTrue(ozNftBase.supportsInterface(type(IONFT721Upgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(ozNftBase.supportsInterface(type(IONFT721CoreUpgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(ozNftBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId), "test_SupportInterface::3");
        assertTrue(ozNftBase.supportsInterface(type(IERC721Upgradeable).interfaceId), "test_SupportInterface::4");
        assertTrue(
            ozNftBase.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId), "test_SupportInterface::4"
        );
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != 0x45aea0ae && interfaceId != 0x01ffc9a7 && interfaceId != 0x5a05180f
                && interfaceId != 0x7965db0b && interfaceId != 0x7260a8cd && interfaceId != 0x2a55205a
                && interfaceId != type(IOZNFTBaseUpgradeable).interfaceId
                && interfaceId != type(IONFT721Upgradeable).interfaceId
                && interfaceId != type(IONFT721CoreUpgradeable).interfaceId
                && interfaceId != type(INFTBaseUpgradeable).interfaceId
                && interfaceId != type(IERC721Upgradeable).interfaceId
                && interfaceId != type(IERC721MetadataUpgradeable).interfaceId
        );

        assertFalse(ozNftBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
