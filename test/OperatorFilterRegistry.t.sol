// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract OperatorRegistryTest is TestHelper {
    address constant DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    OperatorFilterRegistry constant registry = OperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    address blockedAddress = makeAddr("blocked");
    uint256 tokenIdTransfered = 49;

    function setUp() public {
        vm.createSelectFork(StdChains.getChain("avalanche").rpcUrl, 27218980);

        ozNftBase = new OZNFTBaseUpgradeableHarness();
        ozNftBase.initialize(joepegs);

        erc721aBase = new ERC721ABaseUpgradeableHarness();
        erc721aBase.initialize(joepegs);

        erc1155Base = new ERC1155BaseUpgradeableHarness();
        erc1155Base.initialize(joepegs);

        vm.prank(DEFAULT_SUBSCRIPTION);
        registry.updateOperator(DEFAULT_SUBSCRIPTION, blockedAddress, true);

        ozNftBase.mint(tokenIdTransfered);
        erc721aBase.mint(100);
        erc1155Base.mint(tokenIdTransfered);
    }

    function test_Revert_TransferFromBlockedOperator(address alice) public {
        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.transferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.safeTransferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.safeTransferFrom(address(this), alice, tokenIdTransfered, "");

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.transferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.safeTransferFrom(address(this), alice, tokenIdTransfered);

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.safeTransferFrom(address(this), alice, tokenIdTransfered, "");

        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.safeTransferFrom(address(this), alice, tokenIdTransfered, 1, "");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenIdTransfered;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        vm.prank(blockedAddress);
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.safeBatchTransferFrom(address(this), alice, tokenIds, amounts, "");
    }

    function test_Revert_ApprovalToBlockedOperator() public {
        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        ozNftBase.approve(blockedAddress, tokenIdTransfered);

        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc721aBase.approve(blockedAddress, tokenIdTransfered);

        vm.expectRevert(
            abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, blockedAddress)
        );
        erc1155Base.setApprovalForAll(blockedAddress, true);
    }

    function test_ApproveAfterFilterRegistryHasBeenDeactivated() public {
        ozNftBase.setOperatorFilterRegistryAddress(address(0));
        ozNftBase.approve(blockedAddress, tokenIdTransfered);

        erc721aBase.setOperatorFilterRegistryAddress(address(0));
        erc721aBase.approve(blockedAddress, tokenIdTransfered);

        erc1155Base.setOperatorFilterRegistryAddress(address(0));
        erc1155Base.setApprovalForAll(blockedAddress, true);
    }
}
