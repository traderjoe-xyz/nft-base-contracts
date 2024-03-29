// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../TestHelper.sol";

contract PendingOwnableUpgradeableHarness is PendingOwnableUpgradeable {
    function initialize() external initializer {
        __PendingOwnable_init();
    }

    function wrongInitialize() external {
        __PendingOwnable_init();
    }
}

contract PendingOwnableUpgradeableTest is TestHelper {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    PendingOwnableUpgradeableHarness pendingOwnable;

    function setUp() public {
        pendingOwnable = new PendingOwnableUpgradeableHarness();
        pendingOwnable.initialize();
    }

    function test_Initialize() public {
        pendingOwnable = new PendingOwnableUpgradeableHarness();
        pendingOwnable.initialize();

        assertEq(pendingOwnable.owner(), address(this), "test_Initialize::1");
        assertEq(pendingOwnable.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        pendingOwnable.initialize();
    }

    function test_Revert_WrongInitializeImplementation() public {
        pendingOwnable = new PendingOwnableUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        pendingOwnable.wrongInitialize();
    }

    function test_SetPendingOwner(address newOwner) public {
        vm.assume(newOwner != address(0));

        vm.expectEmit(true, true, true, true);
        emit PendingOwnerSet(newOwner);
        pendingOwnable.setPendingOwner(newOwner);

        assertEq(pendingOwnable.pendingOwner(), newOwner, "test_SetPendingOwner::1");
    }

    function test_Revert_SetAddressZeroPendingOwner() public {
        address newOwner = address(0);

        vm.expectRevert(
            abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__AddressZero.selector)
        );
        pendingOwnable.setPendingOwner(newOwner);
    }

    function test_Revert_SetSamePendingOwner(address newOwner) public {
        vm.assume(newOwner != address(0));

        pendingOwnable.setPendingOwner(newOwner);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPendingOwnableUpgradeable.PendingOwnableUpgradeable__PendingOwnerAlreadySet.selector
            )
        );
        pendingOwnable.setPendingOwner(newOwner);
    }

    function test_Revert_SetPendingOwnerWhenNotOwner(address caller, address alice) public {
        vm.assume(caller != address(this) && caller != address(0));
        vm.assume(alice != address(this) && alice != address(0));

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector));
        pendingOwnable.setPendingOwner(alice);
    }

    function test_RevokePendingOwner(address newOwner) public {
        vm.assume(newOwner != address(0));

        pendingOwnable.setPendingOwner(newOwner);

        vm.expectEmit(true, true, true, true);
        emit PendingOwnerSet(address(0));
        pendingOwnable.revokePendingOwner();

        assertEq(pendingOwnable.pendingOwner(), address(0), "test_RevokePendingOwner::1");
    }

    function test_Revert_RevokeWhenNoPendingOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NoPendingOwner.selector)
        );
        pendingOwnable.revokePendingOwner();
    }

    function test_Revert_RevokeWhenNotOwner(address caller, address alice) public {
        vm.assume(caller != address(this) && caller != address(0));
        vm.assume(alice != address(this) && alice != address(0));

        pendingOwnable.setPendingOwner(alice);

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector));
        pendingOwnable.revokePendingOwner();
    }

    function test_BecomeOwner(address newOwner) public {
        vm.assume(newOwner != address(0));

        pendingOwnable.setPendingOwner(newOwner);

        vm.prank(newOwner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), newOwner);
        pendingOwnable.becomeOwner();

        assertEq(pendingOwnable.owner(), newOwner, "test_BecomeOwner::1");
        assertEq(pendingOwnable.pendingOwner(), address(0), "test_BecomeOwner::2");
    }

    function test_Revert_BecomeOwnerWhenNotPendingOwner(address alice, address newOwner) public {
        vm.assume(alice != address(this) && alice != address(0));
        vm.assume(newOwner != address(0) && newOwner != alice);

        pendingOwnable.setPendingOwner(newOwner);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotPendingOwner.selector)
        );
        pendingOwnable.becomeOwner();
    }

    function test_RenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));
        pendingOwnable.renounceOwnership();

        assertEq(pendingOwnable.owner(), address(0), "test_RenounceOwnership::1");
    }

    function test_Revert_RenounceOwnershipWhenNotOwner(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector));
        pendingOwnable.renounceOwnership();
    }

    function test_SupportInterface() public {
        assertTrue(
            pendingOwnable.supportsInterface(type(IERC165Upgradeable).interfaceId)
                && pendingOwnable.supportsInterface(type(IPendingOwnableUpgradeable).interfaceId),
            "test_SupportInterface::1"
        );
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != type(IERC165Upgradeable).interfaceId
                && interfaceId != type(IPendingOwnableUpgradeable).interfaceId
        );

        assertFalse(pendingOwnable.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
