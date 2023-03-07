// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../TestHelper.sol";

import {
    SafeAccessControlEnumerableUpgradeable,
    ISafeAccessControlEnumerableUpgradeable
} from "src/upgradeables/utils/SafeAccessControlEnumerableUpgradeable.sol";

import {IAccessControlUpgradeable} from "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract SafeAccessControlEnumerableUpgradeableHarness is SafeAccessControlEnumerableUpgradeable {
    function initialize() external initializer {
        __SafeAccessControlEnumerable_init();
    }

    function wrongInitialize() external {
        __SafeAccessControlEnumerable_init();
    }
}

contract SafeAccessControlEnumerableUpgradeableTest is TestHelper {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    SafeAccessControlEnumerableUpgradeableHarness accessControl;

    function setUp() public {
        accessControl = new SafeAccessControlEnumerableUpgradeableHarness();
        accessControl.initialize();
    }

    function test_InitialOwner() public {
        assertEq(accessControl.owner(), address(this), "test_InitialOwner::1");
        assertEq(accessControl.pendingOwner(), address(0), "test_InitialOwner::2");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        accessControl.initialize();
    }

    function test_Revert_WrongInitializeImplementation() public {
        accessControl = new SafeAccessControlEnumerableUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        accessControl.wrongInitialize();
    }

    function test_GrantRole(bytes32 role, address alice) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(role, alice, address(this));
        accessControl.grantRole(role, alice);

        assertTrue(accessControl.hasRole(role, alice), "test_GrantRole::1");
        assertEq(accessControl.getRoleMember(role, 0), alice, "test_GrantRole::2");
        assertEq(accessControl.getRoleMemberCount(role), 1, "test_GrantRole::3");
    }

    function test_Revert_GrantRoleWhenNotOwner(bytes32 role, address alice) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner
                    .selector,
                bytes32(0),
                alice
            )
        );
        vm.prank(alice);
        accessControl.grantRole(role, alice);
    }

    function test_Revert_GrantDefaultAdminRole(address alice) public {
        bytes32 role = bytes32(0);
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin
                    .selector
            )
        );
        accessControl.grantRole(role, alice);
    }

    function test_RevokeRole(bytes32 role, address alice) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));

        accessControl.grantRole(role, alice);

        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(role, alice, address(this));
        accessControl.revokeRole(role, alice);

        assertFalse(accessControl.hasRole(role, alice), "test_RevokeRole::1");
        assertEq(accessControl.getRoleMemberCount(role), 0, "test_RevokeRole::3");

        vm.expectRevert();
        accessControl.getRoleMember(role, 0);
    }

    function test_Revert_RevokeRoleWhenNotAdmin(bytes32 role, address alice) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));

        accessControl.grantRole(role, alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner
                    .selector,
                bytes32(0),
                alice
            )
        );
        vm.prank(alice);
        accessControl.revokeRole(role, alice);
    }

    function test_Revert_RevokeDefaultAdminRole(address alice) public {
        bytes32 role = bytes32(0);
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin
                    .selector
            )
        );
        accessControl.revokeRole(role, alice);
    }

    function test_RenounceRole(bytes32 role, address alice) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));

        accessControl.grantRole(role, alice);

        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(role, alice, alice);
        vm.prank(alice);
        accessControl.renounceRole(role, alice);

        assertFalse(accessControl.hasRole(role, alice), "test_RenounceRole::1");
        assertEq(accessControl.getRoleMemberCount(role), 0, "test_RenounceRole::2");

        vm.expectRevert();
        accessControl.getRoleMember(role, 0);
    }

    function test_Revert_RenounceDefaultAdminRole(address alice) public {
        bytes32 role = bytes32(0);
        vm.assume(alice != address(this) && alice != address(0));

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin
                    .selector
            )
        );
        accessControl.renounceRole(role, alice);
    }

    function test_Revert_RenounceSomeoneElseRole(bytes32 role, address alice, address bob) public {
        vm.assume(role != bytes32(0));
        vm.assume(alice != address(this) && alice != address(0));
        vm.assume(bob != address(this) && bob != alice && bob != address(0));

        accessControl.grantRole(role, alice);

        vm.expectRevert("AccessControl: can only renounce roles for self");
        vm.prank(bob);
        accessControl.renounceRole(role, alice);
    }

    function test_TransferOwnership(address alice) public {
        vm.assume(alice != address(this) && alice != address(0));

        accessControl.setPendingOwner(alice);

        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(accessControl.DEFAULT_ADMIN_ROLE(), address(this), alice);
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(accessControl.DEFAULT_ADMIN_ROLE(), alice, alice);
        vm.prank(alice);
        accessControl.becomeOwner();

        assertTrue(accessControl.hasRole(accessControl.DEFAULT_ADMIN_ROLE(), alice), "test_TransferOwnership::1");
        assertEq(accessControl.getRoleMemberCount(accessControl.DEFAULT_ADMIN_ROLE()), 1, "test_TransferOwnership::2");

        assertFalse(
            accessControl.hasRole(accessControl.DEFAULT_ADMIN_ROLE(), address(this)), "test_TransferOwnership::1"
        );
    }

    function test_SupportInterface() public {
        // IAccessControlUpgradeable
        assertTrue(accessControl.supportsInterface(0x7965db0b), "test_SupportInterface::1");
        // IAccessControlEnumerableUpgradeable
        assertTrue(accessControl.supportsInterface(0x5a05180f), "test_SupportInterface::2");
        // IPendingOwnableUpgradeable
        assertTrue(accessControl.supportsInterface(0x45aea0ae), "test_SupportInterface::3");
    }

    function test_DoesNotSupportOtherInterfaces(bytes4 interfaceId) public {
        vm.assume(
            interfaceId != 0x45aea0ae && interfaceId != 0x01ffc9a7 && interfaceId != 0x5a05180f
                && interfaceId != 0x7965db0b
        );

        assertFalse(accessControl.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
