// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./TestHelper.sol";

contract NFTBaseUpgradeableHarness is NFTBaseUpgradeable {
    function initialize(address dummyAddress) external initializer {
        __NFTBase_init(500, dummyAddress, dummyAddress);
    }

    function initialize(address dummyAddress, uint256 joeFee) external initializer {
        __NFTBase_init(joeFee, dummyAddress, dummyAddress);
    }

    function wrongInitialize(address dummyAddress) external {
        __NFTBase_init(500, dummyAddress, dummyAddress);
    }
}

contract NFTBaseUpgradeableTest is TestHelper {
    using stdStorage for StdStorage;

    event OperatorFilterRegistryUpdated(address indexed operatorFilterRegistry);
    event JoeFeeInitialized(uint256 feePercent, address feeCollector);
    event WithdrawAVAXStartTimeSet(uint256 withdrawAVAXStartTime);
    event AvaxWithdraw(address indexed sender, uint256 amount, uint256 fee);
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    NFTBaseUpgradeableHarness nftBase;

    function setUp() public {
        nftBase = new NFTBaseUpgradeableHarness();
        nftBase.initialize(joepegs);

        nftBase.setWithdrawAVAXStartTime(100);
        vm.warp(100);
    }

    function test_Initialize(address joeFeeReceiver) public {
        vm.assume(joeFeeReceiver != address(0));
        nftBase = new NFTBaseUpgradeableHarness();
        nftBase.initialize(joeFeeReceiver);

        assertEq(nftBase.owner(), address(this), "test_Initialize::1");
        assertEq(nftBase.pendingOwner(), address(0), "test_Initest_InitializetialOwner::2");

        assertEq(
            address(nftBase.operatorFilterRegistry()), 0x000000000000AAeB6D7670E522A718067333cd4E, "test_Initialize::3"
        );

        assertEq(nftBase.joeFeePercent(), 500, "test_Initialize::4");
        assertEq(nftBase.joeFeeCollector(), joeFeeReceiver, "test_Initialize::5");

        (address royaltiesReceiver, uint256 royaltiesPercent) = nftBase.royaltyInfo(0, 10_000);
        assertEq(royaltiesReceiver, joeFeeReceiver, "test_Initialize::6");
        assertEq(royaltiesPercent, 500, "test_Initialize::7");
    }

    function test_GetProjectOwnerRole() public {
        assertEq(nftBase.getProjectOwnerRole(), keccak256("PROJECT_OWNER_ROLE"), "test_GetProjectOwnerRole::1");
    }

    function test_Revert_InitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        nftBase.initialize(joepegs);
    }

    function test_Revert_WrongInitializeImplementation() public {
        nftBase = new NFTBaseUpgradeableHarness();
        vm.expectRevert("Initializable: contract is not initializing");
        nftBase.wrongInitialize(joepegs);
    }

    function test_Revert_InvalidJoeFeeReceiver() public {
        nftBase = new NFTBaseUpgradeableHarness();

        vm.expectRevert(INFTBaseUpgradeable.NFTBase__InvalidJoeFeeCollector.selector);
        nftBase.initialize(address(0));
    }

    function test_Revert_InvalidJoeFeePercent(uint256 joeFeePercent, address joeFeeReceiver) public {
        joeFeePercent = bound(joeFeePercent, 10_001, type(uint256).max);
        vm.assume(joeFeeReceiver != address(0));

        nftBase = new NFTBaseUpgradeableHarness();

        vm.expectRevert(INFTBaseUpgradeable.NFTBase__InvalidPercent.selector);
        nftBase.initialize(joeFeeReceiver, joeFeePercent);
    }

    function test_SetOperatorFilterRegistry(address newRegistry) public {
        nftBase = new NFTBaseUpgradeableHarness();
        nftBase.initialize(joepegs);

        vm.expectEmit(true, true, true, true);
        emit OperatorFilterRegistryUpdated(newRegistry);
        nftBase.setOperatorFilterRegistryAddress(newRegistry);

        assertEq(address(nftBase.operatorFilterRegistry()), newRegistry, "test_SetOperatorFilterRegistry::1");
    }

    function test_Revert_SetOperatorFilterRegistryWhenNotOwner(address alice, address newRegistry) public {
        vm.assume(alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        nftBase.setOperatorFilterRegistryAddress(newRegistry);
    }

    function test_SetRoyaltyInfo(address royaltiesReceiver, uint256 royaltiesPercent) public {
        vm.assume(royaltiesReceiver != address(0));
        royaltiesPercent = bound(royaltiesPercent, 0, 2_500);

        vm.expectEmit(true, true, true, true);
        emit DefaultRoyaltySet(royaltiesReceiver, royaltiesPercent);
        nftBase.setRoyaltyInfo(royaltiesReceiver, uint96(royaltiesPercent));

        (address contractRoyaltiesReceiver, uint256 contractRoyaltiesPercent) = nftBase.royaltyInfo(0, 10_000);
        assertEq(contractRoyaltiesReceiver, royaltiesReceiver, "test_SetRoyaltyInfo::1");
        assertEq(contractRoyaltiesPercent, royaltiesPercent, "test_SetRoyaltyInfo::2");
    }

    function test_Revert_SetAddressZeroAsRoyaltyReceiver() public {
        vm.expectRevert("ERC2981: invalid receiver");
        nftBase.setRoyaltyInfo(address(0), 500);
    }

    function test_Revert_SetRoyaltyPercentageTooBig(address royaltyReceiver, uint96 royaltiesPercent) public {
        vm.assume(royaltiesPercent > 2_500);
        vm.expectRevert(INFTBaseUpgradeable.NFTBase__InvalidRoyaltyInfo.selector);
        nftBase.setRoyaltyInfo(royaltyReceiver, royaltiesPercent);
    }

    function test_Revert_SetRoyaltyInfoWhenNotOwner(address alice, address royaltyReceiver, uint96 royaltiesPercent)
        public
    {
        vm.assume(alice != address(this));
        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        nftBase.setRoyaltyInfo(royaltyReceiver, royaltiesPercent);
    }

    function test_WithdrawAVAX(uint256 amount, address alice) public {
        amount = bound(amount, 0.01 ether, 100_000 ether);
        deal(address(nftBase), amount);

        uint256 fee = (amount * nftBase.joeFeePercent()) / 10_000;
        uint256 feeCollectorBalanceBefore = joepegs.balance;

        // vm.expectEmit(true, true, true, true);
        // emit AvaxWithdraw(alice, amount - fee, fee);
        nftBase.withdrawAVAX(alice);

        assertEq(joepegs.balance - feeCollectorBalanceBefore, fee, "test_WithdrawAVAX::1");
        assertEq(alice.balance, amount - fee, "test_WithdrawAVAX::2");
    }

    function test_WithdrawAVAXWhenProjectOwner(address alice, address bob, uint256 amount) public {
        vm.assume(alice != address(this));
        vm.assume(bob != address(this) && bob != joepegs);

        amount = bound(amount, 0.01 ether, 100_000 ether);
        deal(address(nftBase), amount);

        uint256 fee = (amount * nftBase.joeFeePercent()) / 10_000;
        uint256 feeCollectorBalanceBefore = joepegs.balance;

        nftBase.grantRole(nftBase.getProjectOwnerRole(), alice);

        vm.prank(alice);
        nftBase.withdrawAVAX(bob);

        assertEq(joepegs.balance - feeCollectorBalanceBefore, fee, "test_WithdrawAVAXWhenProjectOwner::1");
        assertEq(bob.balance, amount - fee, "test_WithdrawAVAXWhenProjectOwner::2");
    }

    function test_Revert_WithdrawAVAXWhenNotOwner(address alice, uint256 amount) public {
        vm.assume(alice != address(this));

        amount = bound(amount, 10_000, 100_000 ether);
        deal(address(nftBase), amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerableUpgradeable
                    .SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner
                    .selector,
                nftBase.getProjectOwnerRole(),
                alice
            )
        );
        vm.prank(alice);
        nftBase.withdrawAVAX(alice);
    }

    function test_Revert_WithdrawAVAXWhenNotReady(uint256 timestamp) public {
        timestamp = bound(timestamp, 0, nftBase.withdrawAVAXStartTime() - 1);

        vm.warp(timestamp);

        vm.expectRevert(INFTBaseUpgradeable.NFTBase__WithdrawAVAXNotAvailable.selector);
        nftBase.withdrawAVAX(address(this));
    }

    function test_Revert_WithdrawAVAXToNonCompatibleContract(uint256 amount) public {
        amount = bound(amount, 10_000, 100_000 ether);
        deal(address(nftBase), amount);

        vm.expectRevert(INFTBaseUpgradeable.NFTBase__TransferFailed.selector);
        nftBase.withdrawAVAX(address(this));
    }

    function test_Revert_WithdrawAVAXToNonCompatibleJoeFeeCollector(address alice, uint256 amount) public {
        vm.assume(alice != address(this));
        amount = bound(amount, 10_000, 100_000 ether);
        deal(address(nftBase), amount);

        stdstore.target(address(nftBase)).sig("joeFeeCollector()").checked_write(address(this));
        assertEq(nftBase.joeFeeCollector(), address(this), "test_Revert_WithdrawAVAXToNonCompatibleJoeFeeCollector::1");

        vm.expectRevert(INFTBaseUpgradeable.NFTBase__TransferFailed.selector);
        nftBase.withdrawAVAX(alice);
    }

    function test_SetWithdrawAVAXStartTime(uint256 newTime) public {
        vm.expectEmit(true, true, true, true);
        emit WithdrawAVAXStartTimeSet(newTime);
        nftBase.setWithdrawAVAXStartTime(newTime);
    }

    function test_Revert_SetWithdrawAVAXStartTimeWhenNotOwner(address alice, uint256 newTime) public {
        vm.assume(alice != address(this));

        vm.expectRevert(IPendingOwnableUpgradeable.PendingOwnableUpgradeable__NotOwner.selector);
        vm.prank(alice);
        nftBase.setWithdrawAVAXStartTime(newTime);
    }

    function test_SupportInterface() public {
        assertTrue(
            nftBase.supportsInterface(type(IERC165Upgradeable).interfaceId)
                && nftBase.supportsInterface(type(IPendingOwnableUpgradeable).interfaceId)
                && nftBase.supportsInterface(type(IAccessControlUpgradeable).interfaceId)
                && nftBase.supportsInterface(type(IAccessControlEnumerableUpgradeable).interfaceId)
                && nftBase.supportsInterface(type(ISafePausableUpgradeable).interfaceId)
                && nftBase.supportsInterface(type(IERC2981Upgradeable).interfaceId)
                && nftBase.supportsInterface(type(INFTBaseUpgradeable).interfaceId),
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
        );

        assertFalse(nftBase.supportsInterface(interfaceId), "test_DoesNotSupportOtherInterfaces::1");
    }
}
