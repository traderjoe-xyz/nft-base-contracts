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

import {OZNFTBaseUpgradeable, IOZNFTBaseUpgradeable} from "src/upgradeables/OZNFTBaseUpgradeable.sol";
import {INFTBaseUpgradeable} from "src/upgradeables/interfaces/INFTBaseUpgradeable.sol";
import {IPendingOwnableUpgradeable} from "src/upgradeables/interfaces/utils/IPendingOwnableUpgradeable.sol";

contract OZNFTBaseUpgradeableHarness is OZNFTBaseUpgradeable {
    function initialize(address dummyAddress) external initializer {
        __OZNFTBase_init("OZNFT Base Upgradeable Harness", "OBUH", dummyAddress, 500, dummyAddress, dummyAddress);
    }

    function wrongInitialize(address dummyAddress) external {
        __OZNFTBase_init("OZNFT Base Upgradeable Harness", "OBUH", dummyAddress, 500, dummyAddress, dummyAddress);
    }
}

contract OZNFTBaseUpgradeableTest is TestHelper {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

    OZNFTBaseUpgradeableHarness ozNFTBase;

    function setUp() public {
        ozNFTBase = new OZNFTBaseUpgradeableHarness();
        ozNFTBase.initialize(joepegs);
    }

    function test_Initialize(address dummyAddress) public {
        vm.assume(dummyAddress != address(0));
        ozNFTBase = new OZNFTBaseUpgradeableHarness();
        ozNFTBase.initialize(dummyAddress);

        assertEq(ozNFTBase.owner(), address(this), "test_Initialize::1");
        assertEq(ozNFTBase.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");

        assertEq(
            address(ozNFTBase.operatorFilterRegistry()),
            0x000000000000AAeB6D7670E522A718067333cd4E,
            "test_Initialize::3"
        );

        assertEq(ozNFTBase.joeFeePercent(), 500, "test_Initialize::4");
        assertEq(ozNFTBase.joeFeeCollector(), dummyAddress, "test_Initialize::5");

        (address royaltiesReceiver, uint256 royaltiesPercent) = ozNFTBase.royaltyInfo(0, 10_000);
        assertEq(royaltiesReceiver, dummyAddress, "test_Initialize::6");
        assertEq(royaltiesPercent, 500, "test_Initialize::7");

        assertEq(address(ozNFTBase.lzEndpoint()), dummyAddress, "test_Initialize::8");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        ozNFTBase.initialize(joepegs);
    }

    function test_Revert_WrongInitializeImplementation() public {
        ozNFTBase = new OZNFTBaseUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        ozNFTBase.wrongInitialize(joepegs);
    }

    function test_SetBaseURI(string memory baseURI) public {
        vm.expectEmit(true, true, true, false);
        emit BaseURISet(baseURI);
        ozNFTBase.setBaseURI(baseURI);

        assertEq(ozNFTBase.baseURI(), baseURI, "test_SetBaseURI::1");
    }

    function test_Revert_SetBaseURIWhenNotOwner(address alice, string memory baseURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        ozNFTBase.setBaseURI(baseURI);
    }

    function test_SetUnrevealedURI(string memory unrevealedURI) public {
        vm.expectEmit(true, true, true, false);
        emit UnrevealedURISet(unrevealedURI);
        ozNFTBase.setUnrevealedURI(unrevealedURI);

        assertEq(ozNFTBase.unrevealedURI(), unrevealedURI, "test_SetUnrevealedURI::1");
    }

    function test_Revert_SetUnrevealedURIWhenNotOwner(address alice, string memory unrevealedURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        ozNFTBase.setUnrevealedURI(unrevealedURI);
    }

    function test_SupportInterface() public {
        assertTrue(ozNFTBase.supportsInterface(type(IOZNFTBaseUpgradeable).interfaceId), "test_SupportInterface::1");
        assertTrue(ozNFTBase.supportsInterface(type(IONFT721Upgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(ozNFTBase.supportsInterface(type(IONFT721CoreUpgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(ozNFTBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId), "test_SupportInterface::3");
        assertTrue(ozNFTBase.supportsInterface(type(IERC721Upgradeable).interfaceId), "test_SupportInterface::4");
        assertTrue(
            ozNFTBase.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId), "test_SupportInterface::4"
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

        assertFalse(ozNFTBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
