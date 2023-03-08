// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {PausableUpgradeable} from "openzeppelin-upgradeable/security/PausableUpgradeable.sol";

import {SafeAccessControlEnumerableUpgradeable} from "./SafeAccessControlEnumerableUpgradeable.sol";
import {ISafePausableUpgradeable} from "../interfaces/ISafePausableUpgradeable.sol";

abstract contract SafePausableUpgradeable is
    SafeAccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ISafePausableUpgradeable
{
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    bytes32 internal constant PAUSER_ADMIN_ROLE = keccak256("PAUSER_ADMIN_ROLE");
    bytes32 internal constant UNPAUSER_ADMIN_ROLE = keccak256("UNPAUSER_ADMIN_ROLE");

    function __SafePausable_init() internal onlyInitializing {
        __SafeAccessControlEnumerable_init();
        __Pausable_init();

        __SafePausable_init_unchained();
    }

    function __SafePausable_init_unchained() internal onlyInitializing {
        _setRoleAdmin(PAUSER_ROLE, PAUSER_ADMIN_ROLE);
        _setRoleAdmin(UNPAUSER_ROLE, UNPAUSER_ADMIN_ROLE);
    }

    /**
     * @notice Returns the pauser role.
     */
    function getPauserRole() public pure override returns (bytes32) {
        return PAUSER_ROLE;
    }

    /**
     * @notice Returns the unpauser role.
     */
    function getUnpauserRole() public pure override returns (bytes32) {
        return UNPAUSER_ROLE;
    }

    /**
     * @notice Returns the pauser admin role.
     */
    function getPauserAdminRole() public pure override returns (bytes32) {
        return PAUSER_ADMIN_ROLE;
    }

    /**
     * @notice Returns the unpauser admin role.
     */
    function getUnpauserAdminRole() public pure override returns (bytes32) {
        return UNPAUSER_ADMIN_ROLE;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SafeAccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return interfaceId == type(ISafePausableUpgradeable).interfaceId
            || SafeAccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Pauses the contract.
     * @dev Sensible part of a contract might be pausable for security reasons.
     *
     * Requirements:
     * - the caller must be the `owner` or have the ``role`` role.
     * - the contrat needs to be unpaused.
     */
    function pause() public virtual override onlyOwnerOrRole(PAUSER_ROLE) {
        if (paused()) revert SafePausableUpgradeable__AlreadyPaused();
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Sensible part of a contract might be pausable for security reasons.
     *
     * Requirements:
     * - the caller must be the `owner` or have the ``role`` role.
     * - the contrat needs to be unpaused.
     */
    function unpause() public virtual override onlyOwnerOrRole(UNPAUSER_ROLE) {
        if (!paused()) revert SafePausableUpgradeable__AlreadyUnpaused();
        _unpause();
    }
}
