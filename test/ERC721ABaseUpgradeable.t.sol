// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {IERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from
    "openzeppelin-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import {ERC721ABaseUpgradeable, IERC721ABaseUpgradeable} from "src/upgradeables/ERC721ABaseUpgradeable.sol";
import {INFTBaseUpgradeable} from "src/upgradeables/interfaces/INFTBaseUpgradeable.sol";
import {IPendingOwnableUpgradeable} from "src/upgradeables/interfaces/IPendingOwnableUpgradeable.sol";

contract ERC721ABaseUpgradeableHarness is ERC721ABaseUpgradeable {
    function initialize(address dummyAddress) external initializer initializerERC721A {
        __ERC721ABase_init("ERC721A Base Upgradeable Harness", "EBUH", 500, dummyAddress, dummyAddress);
    }

    function wrongInitialize(address dummyAddress) external {
        __ERC721ABase_init("ERC721A Base Upgradeable Harness", "EBUH", 500, dummyAddress, dummyAddress);
    }
}

contract ERC721ABaseUpgradeableTest is TestHelper {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

    ERC721ABaseUpgradeableHarness erc721aBase;

    function setUp() public {
        erc721aBase = new ERC721ABaseUpgradeableHarness();
        erc721aBase.initialize(joepegs);

        erc721aBase.setWithdrawAVAXStartTime(100);
        vm.warp(100);
    }

    function test_Initialize(address joeFeeReceiver) public {
        vm.assume(joeFeeReceiver != address(0));
        erc721aBase = new ERC721ABaseUpgradeableHarness();
        erc721aBase.initialize(joeFeeReceiver);

        assertEq(erc721aBase.owner(), address(this), "test_Initialize::1");
        assertEq(erc721aBase.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");

        assertEq(
            address(erc721aBase.operatorFilterRegistry()),
            0x000000000000AAeB6D7670E522A718067333cd4E,
            "test_Initialize::3"
        );

        assertEq(erc721aBase.joeFeePercent(), 500, "test_Initialize::4");
        assertEq(erc721aBase.joeFeeCollector(), joeFeeReceiver, "test_Initialize::5");

        (address royaltiesReceiver, uint256 royaltiesPercent) = erc721aBase.royaltyInfo(0, 10_000);
        assertEq(royaltiesReceiver, joeFeeReceiver, "test_Initialize::6");
        assertEq(royaltiesPercent, 500, "test_Initialize::7");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        erc721aBase.initialize(joepegs);
    }

    function test_Revert_WrongInitializeImplementation() public {
        erc721aBase = new ERC721ABaseUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        erc721aBase.wrongInitialize(joepegs);
    }

    function test_SetBaseURI(string memory baseURI) public {
        vm.expectEmit(true, true, true, false);
        emit BaseURISet(baseURI);
        erc721aBase.setBaseURI(baseURI);

        assertEq(erc721aBase.baseURI(), baseURI, "test_SetBaseURI::1");
    }

    function test_Revert_SetBaseURIWhenNotOwner(address alice, string memory baseURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        erc721aBase.setBaseURI(baseURI);
    }

    function test_SetUnrevealedURI(string memory unrevealedURI) public {
        vm.expectEmit(true, true, true, false);
        emit UnrevealedURISet(unrevealedURI);
        erc721aBase.setUnrevealedURI(unrevealedURI);

        assertEq(erc721aBase.unrevealedURI(), unrevealedURI, "test_SetUnrevealedURI::1");
    }

    function test_Revert_SetUnrevealedURIWhenNotOwner(address alice, string memory unrevealedURI) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        erc721aBase.setUnrevealedURI(unrevealedURI);
    }

    function test_SupportInterface() public {
        assertTrue(erc721aBase.supportsInterface(type(IERC721ABaseUpgradeable).interfaceId), "test_SupportInterface::1");
        assertTrue(erc721aBase.supportsInterface(type(IERC721AUpgradeable).interfaceId), "test_SupportInterface::2");
        assertTrue(erc721aBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId), "test_SupportInterface::3");
        assertTrue(erc721aBase.supportsInterface(type(IERC721Upgradeable).interfaceId), "test_SupportInterface::4");
        assertTrue(
            erc721aBase.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId), "test_SupportInterface::4"
        );
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != 0x45aea0ae && interfaceId != 0x01ffc9a7 && interfaceId != 0x5a05180f
                && interfaceId != 0x7965db0b && interfaceId != 0x7260a8cd && interfaceId != 0x2a55205a
                && interfaceId != type(IERC721ABaseUpgradeable).interfaceId
                && interfaceId != type(IERC721AUpgradeable).interfaceId
                && interfaceId != type(INFTBaseUpgradeable).interfaceId
                && interfaceId != type(IERC721Upgradeable).interfaceId
                && interfaceId != type(IERC721MetadataUpgradeable).interfaceId
        );

        assertFalse(erc721aBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
