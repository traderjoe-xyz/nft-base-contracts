// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

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

    function test_SetLzEndpointAddress(address lzEndpoint) public {
        vm.assume(lzEndpoint != address(0));
        ozNftBase.setLzEndpoint(lzEndpoint);

        assertEq(address(ozNftBase.lzEndpoint()), lzEndpoint, "test_SetLzEndpointAddress::1");
    }

    function test_Revert_SetLzEndpointAddressWhenNotOwner(address alice, address lzEndpoint) public {
        vm.assume(alice != address(0) && alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        ozNftBase.setLzEndpoint(lzEndpoint);
    }

    function test_Revert_SetLzEndpointAddressToZero() public {
        vm.expectRevert(IOZNFTBaseUpgradeable.OZNFTBaseUpgradeable__InvalidAddress.selector);
        ozNftBase.setLzEndpoint(address(0));
    }

    function test_SupportInterface() public {
        assertTrue(
            ozNftBase.supportsInterface(type(IERC165Upgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IPendingOwnableUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IAccessControlUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IAccessControlEnumerableUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(ISafePausableUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IERC2981Upgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IOZNFTBaseUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IONFT721Upgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IONFT721CoreUpgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IERC721Upgradeable).interfaceId)
                && ozNftBase.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId),
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
                && interfaceId != type(INFTBaseUpgradeable).interfaceId
                && interfaceId != type(IERC2981Upgradeable).interfaceId
                && interfaceId != type(IOZNFTBaseUpgradeable).interfaceId
                && interfaceId != type(IONFT721Upgradeable).interfaceId
                && interfaceId != type(IONFT721CoreUpgradeable).interfaceId
                && interfaceId != type(IERC721Upgradeable).interfaceId
                && interfaceId != type(IERC721MetadataUpgradeable).interfaceId
        );

        assertFalse(ozNftBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
