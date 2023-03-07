// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../TestHelper.sol";

import {SafePausableUpgradeable, ISafePausableUpgradeable} from "src/upgradeables/utils/SafePausableUpgradeable.sol";

import {ISafeAccessControlEnumerableUpgradeable} from
    "src/upgradeables/interfaces/ISafeAccessControlEnumerableUpgradeable.sol";

contract SafePausableUpgradeableHarness is SafePausableUpgradeable {
    function initialize() external initializer {
        __SafePausable_init();
    }

    function wrongInitialize() external {
        __SafePausable_init();
    }
}

contract SafePausableUpgradeableTest is TestHelper {
    event Paused(address account);
    event Unpaused(address account);

    SafePausableUpgradeableHarness pausable;

    function setUp() public {
        pausable = new SafePausableUpgradeableHarness();
        pausable.initialize();
    }

    function test_InitialOwner() public {
        assertEq(pausable.owner(), address(this), "test_InitialOwner::1");
        assertEq(pausable.pendingOwner(), address(0), "test_InitialOwner::2");
    }

    function test_getDefaultRoles() public {
        assertEq(pausable.getPauserRole(), keccak256("PAUSER_ROLE"), "test_getDefaultRoles::1");
        assertEq(pausable.getUnpauserRole(), keccak256("UNPAUSER_ROLE"), "test_getDefaultRoles::2");
        assertEq(pausable.getPauserAdminRole(), keccak256("PAUSER_ADMIN_ROLE"), "test_getDefaultRoles::3");
        assertEq(pausable.getUnpauserAdminRole(), keccak256("UNPAUSER_ADMIN_ROLE"), "test_getDefaultRoles::4");

        assertEq(
            pausable.getRoleAdmin(pausable.getPauserRole()), pausable.getPauserAdminRole(), "test_getDefaultRoles::5"
        );
        assertEq(
            pausable.getRoleAdmin(pausable.getUnpauserRole()),
            pausable.getUnpauserAdminRole(),
            "test_getDefaultRoles::6"
        );
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        pausable.initialize();
    }

    function test_Revert_WrongInitializeImplementation() public {
        pausable = new SafePausableUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        pausable.wrongInitialize();
    }

    function test_Pause() public {
        vm.expectEmit(true, true, true, true);
        emit Paused(address(this));
        pausable.pause();

        assertTrue(pausable.paused(), "test_Pause::1");
    }

    function test_PauseWithRole(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        pausable.grantRole(pausable.getPauserRole(), alice);

        vm.expectEmit(true, true, true, true);
        emit Paused(alice);
        vm.prank(alice);
        pausable.pause();

        assertTrue(pausable.paused(), "test_PauseWithRole::1");
    }

    function test_Revert_PauseWhenNotOwner(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner
                    .selector,
                pausable.getPauserRole(),
                alice
            )
        );
        vm.prank(alice);
        pausable.pause();
    }

    function test_Revert_PauseWhenAlreadyPaused() public {
        pausable.pause();

        vm.expectRevert(
            abi.encodeWithSelector(ISafePausableUpgradeable.SafePausableUpgradeable__AlreadyPaused.selector)
        );
        pausable.pause();
    }

    function test_Unpause() public {
        pausable.pause();

        vm.expectEmit(true, true, true, true);
        emit Unpaused(address(this));
        pausable.unpause();

        assertFalse(pausable.paused(), "test_UnPause::1");
    }

    function test_UnpauseWithUnpauserRole(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        pausable.grantRole(pausable.getUnpauserRole(), alice);
        pausable.pause();

        vm.expectEmit(true, true, true, true);
        emit Unpaused(alice);
        vm.prank(alice);
        pausable.unpause();

        assertFalse(pausable.paused(), "test_UnpauseWithUnpauserRole::1");
    }

    function test_UnpauseWhenNotOwner(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        pausable.pause();

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner
                    .selector,
                pausable.getUnpauserRole(),
                alice
            )
        );
        vm.prank(alice);
        pausable.unpause();
    }

    function test_SupportInterface() public {
        // ISafePausableUpgradeable
        assertTrue(pausable.supportsInterface(0x7260a8cd), "test_SupportInterface::1");
        // IAccessControlEnumerableUpgradeable
        assertTrue(pausable.supportsInterface(0x5a05180f), "test_SupportInterface::2");
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != 0x45aea0ae && interfaceId != 0x01ffc9a7 && interfaceId != 0x5a05180f
                && interfaceId != 0x7965db0b && interfaceId != 0x7260a8cd
        );

        assertFalse(pausable.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
