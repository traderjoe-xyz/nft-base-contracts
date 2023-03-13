// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {StringsUpgradeable} from "openzeppelin-upgradeable/utils/StringsUpgradeable.sol";

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import {SafePausableUpgradeable} from "./utils/SafePausableUpgradeable.sol";
import {INFTBaseUpgradeable} from "./interfaces/INFTBaseUpgradeable.sol";

abstract contract NFTBaseUpgradeable is
    SafePausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable,
    INFTBaseUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 private constant BASIS_POINT_PRECISION = 10_000;
    uint96 private constant DEFAULT_ROYALTIES_PERCENTAGE = 500; // 5%
    uint96 private constant MAXIMUM_ROYALTIES_PERCENTAGE = 2_500; // 25%

    /**
     * @dev Role granted to project owners
     */
    bytes32 private constant PROJECT_OWNER_ROLE = keccak256("PROJECT_OWNER_ROLE");

    /**
     * @dev OpenSea's filter registry and subscription address
     */
    address private constant OPENSEA_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;
    address private constant OPENSEA_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /**
     * @notice Contract filtering allowed operators, preventing unauthorized contract to transfer NFTs
     * By default, Joepegs contracts are subscribed to OpenSea's Curated Subscription Address at 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
     */
    IOperatorFilterRegistry public override operatorFilterRegistry;

    /**
     * @notice The fees collected by Joepegs on the sale benefits
     * @dev In basis points e.g 100 for 1%
     */
    uint256 public override joeFeePercent;

    /**
     * @notice The address to which the fees on the sale will be sent
     */
    address public override joeFeeCollector;

    /**
     * @notice Start time when funds can be withdrawn
     */
    uint256 public override withdrawAVAXStartTime;

    /**
     * @notice Allow spending tokens from addresses with balance
     * Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
     * from an EOA.
     */
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Allow approving tokens transfers
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function __NFTBase_init(uint256 _joeFeePercent, address _joeFeeCollector, address royaltyReceiver)
        internal
        onlyInitializing
    {
        __SafePausable_init();
        __ERC2981_init();

        __NFTBase_init_unchained(_joeFeePercent, _joeFeeCollector, royaltyReceiver);
    }

    function __NFTBase_init_unchained(uint256 _joeFeePercent, address _joeFeeCollector, address royaltyReceiver)
        internal
        onlyInitializing
    {
        // Initialize the operator filter registry and subscribe to OpenSea's list
        IOperatorFilterRegistry _operatorFilterRegistry = IOperatorFilterRegistry(OPENSEA_FILTER_REGISTRY);

        if (address(_operatorFilterRegistry).code.length > 0) {
            _operatorFilterRegistry.registerAndSubscribe(address(this), OPENSEA_SUBSCRIPTION);
        }

        _updateOperatorFilterRegistryAddress(_operatorFilterRegistry);

        _initializeJoeFee(_joeFeePercent, _joeFeeCollector);

        _setDefaultRoyalty(royaltyReceiver, DEFAULT_ROYALTIES_PERCENTAGE);
    }

    /**
     * @notice Returns the project owner role
     */
    function getProjectOwnerRole() public pure override returns (bytes32) {
        return PROJECT_OWNER_ROLE;
    }

    /**
     * @notice Sets a new withdraw AVAX start time
     * @param newWithdrawAVAXStartTime New withdraw AVAX start time
     */
    function setWithdrawAVAXStartTime(uint256 newWithdrawAVAXStartTime) external override onlyOwner {
        withdrawAVAXStartTime = newWithdrawAVAXStartTime;
        emit WithdrawAVAXStartTimeSet(newWithdrawAVAXStartTime);
    }

    /**
     * @notice Withdraw AVAX to the given recipient
     * @param to Recipient of the earned AVAX
     */
    function withdrawAVAX(address to) external override onlyOwnerOrRole(PROJECT_OWNER_ROLE) nonReentrant {
        if (block.timestamp < withdrawAVAXStartTime || withdrawAVAXStartTime == 0) {
            revert NFTBase__WithdrawAVAXNotAvailable();
        }

        uint256 amount = address(this).balance;
        uint256 fee;
        uint256 feePercent = joeFeePercent;

        if (feePercent > 0) {
            fee = (amount * feePercent) / BASIS_POINT_PRECISION;
            amount = amount - fee;

            _send(joeFeeCollector, fee);
        }

        _send(to, amount);

        emit AvaxWithdraw(to, amount, fee);
    }

    /**
     * @notice Set the operator filter registry address
     * @param newOperatorFilterRegistry New operator filter registry
     */
    function setOperatorFilterRegistryAddress(address newOperatorFilterRegistry) external override onlyOwner {
        _updateOperatorFilterRegistryAddress(IOperatorFilterRegistry(newOperatorFilterRegistry));
    }

    /**
     * @notice Set the royalty fee
     * @param receiver Royalty fee collector
     * @param feePercent Royalty fee percent in basis point
     */
    function setRoyaltyInfo(address receiver, uint96 feePercent) external override onlyOwner {
        // Royalty fees are limited to 25%
        if (feePercent > MAXIMUM_ROYALTIES_PERCENTAGE) {
            revert NFTBase__InvalidRoyaltyInfo();
        }
        _setDefaultRoyalty(receiver, feePercent);
        emit DefaultRoyaltySet(receiver, feePercent);
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SafePausableUpgradeable, ERC2981Upgradeable, INFTBaseUpgradeable)
        returns (bool)
    {
        return interfaceId == type(INFTBaseUpgradeable).interfaceId || ERC2981Upgradeable.supportsInterface(interfaceId)
            || SafePausableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Update the address that the contract will make OperatorFilter checks against. When set to the zero
     * address, checks will be bypassed.
     * @param newRegistry The address of the new OperatorFilterRegistry
     */
    function _updateOperatorFilterRegistryAddress(IOperatorFilterRegistry newRegistry) private {
        operatorFilterRegistry = newRegistry;
        emit OperatorFilterRegistryUpdated(address(newRegistry));
    }

    /**
     * @notice Initialize the sales fee percent taken by Joepegs and address that collects the fees
     * @param _joeFeePercent The fees collected by Joepegs on the sale benefits
     * @param _joeFeeCollector The address to which the fees on the sale will be sent
     */
    function _initializeJoeFee(uint256 _joeFeePercent, address _joeFeeCollector) private {
        if (_joeFeePercent > BASIS_POINT_PRECISION) {
            revert NFTBase__InvalidPercent();
        }
        if (_joeFeeCollector == address(0)) {
            revert NFTBase__InvalidJoeFeeCollector();
        }
        joeFeePercent = _joeFeePercent;
        joeFeeCollector = _joeFeeCollector;
        emit JoeFeeInitialized(_joeFeePercent, _joeFeeCollector);
    }

    /**
     * @dev Checks if the address (the operator) trying to transfer the NFT is allowed
     * @param operator Address of the operator
     */
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /**
     * @dev Sends AVAX to the given address
     * @param to Address to send AVAX to
     * @param amount Amount of AVAX to send
     */
    function _send(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert NFTBase__TransferFailed();
        }
    }

    /**
     * @dev Verifies that enough AVAX has been sent by the sender and refunds the extra tokens if any
     * @param price The price paid by the sender for minting NFTs
     */
    function _refundIfOver(uint256 price) internal {
        if (msg.value < price) {
            revert NFTBase__NotEnoughAVAX(price);
        }
        if (msg.value > price) {
            (bool success,) = msg.sender.call{value: msg.value - price}("");
            if (!success) {
                revert NFTBase__TransferFailed();
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
