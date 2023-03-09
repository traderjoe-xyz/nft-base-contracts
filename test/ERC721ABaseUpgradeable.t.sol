// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

contract ERC721ABaseUpgradeableTest is TestHelper {
    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);

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
        assertTrue(
            erc721aBase.supportsInterface(type(IERC165Upgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IPendingOwnableUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IAccessControlUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IAccessControlEnumerableUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(ISafePausableUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IERC2981Upgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IERC721ABaseUpgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IERC721Upgradeable).interfaceId)
                && erc721aBase.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId),
            "test_SupportInterface::1"
        );
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != type(IERC165Upgradeable).interfaceId
                && interfaceId != type(IPendingOwnableUpgradeable).interfaceId
                && interfaceId != type(IAccessControlUpgradeable).interfaceId
                && interfaceId != type(IAccessControlEnumerableUpgradeable).interfaceId
                && interfaceId != type(ISafePausableUpgradeable).interfaceId
                && interfaceId != type(IERC2981Upgradeable).interfaceId
                && interfaceId != type(INFTBaseUpgradeable).interfaceId
                && interfaceId != type(IERC721ABaseUpgradeable).interfaceId
                && interfaceId != type(IERC721Upgradeable).interfaceId
                && interfaceId != type(IERC721MetadataUpgradeable).interfaceId
        );

        assertFalse(erc721aBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
