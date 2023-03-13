// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract LayerZeroTest is TestHelper {
    uint16 chainId_A = 1;
    uint16 chainId_B = 2;

    OZNFTBaseUpgradeableHarness ozNFT_A;
    OZNFTBaseUpgradeableHarness ozNFT_B;

    LZEndpointMock lzEndpoint_A;
    LZEndpointMock lzEndpoint_B;

    bytes defaultAdapterParams;

    function setUp() public {
        lzEndpoint_A = new LZEndpointMock(chainId_A);
        lzEndpoint_B = new LZEndpointMock(chainId_B);

        ozNFT_A = new OZNFTBaseUpgradeableHarness();
        ozNFT_B = new OZNFTBaseUpgradeableHarness();
        ozNFT_A.initialize(address(lzEndpoint_A), joepegs);
        ozNFT_B.initialize(address(lzEndpoint_B), joepegs);

        lzEndpoint_A.setDestLzEndpoint(address(ozNFT_B), address(lzEndpoint_B));
        lzEndpoint_B.setDestLzEndpoint(address(ozNFT_A), address(lzEndpoint_A));

        // set each contracts source address so it can send to each other
        ozNFT_A.setTrustedRemote(chainId_B, abi.encodePacked(address(ozNFT_B), address(ozNFT_A)));
        ozNFT_B.setTrustedRemote(chainId_A, abi.encodePacked(address(ozNFT_A), address(ozNFT_B)));

        vm.deal(address(lzEndpoint_A), 10 ether);
        vm.deal(address(lzEndpoint_B), 10 ether);

        vm.label(address(ozNFT_A), "ozNFT A");
        vm.label(address(ozNFT_B), "ozNFT B");
        vm.label(address(lzEndpoint_A), "lzEndpoint A");
        vm.label(address(lzEndpoint_B), "lzEndpoint B");
    }

    function test_SendToken(address alice, uint256 tokenId) public {
        vm.assume(alice != address(0) && alice.code.length == 0);
        deal(alice, 10 ether);

        ozNFT_A.mint(tokenId);
        address owner = ozNFT_A.owner();

        // verify the owner of the token is on the source chain
        assertEq(ozNFT_A.ownerOf(tokenId), owner);

        // token doesn't exist on other chain
        vm.expectRevert("ERC721: invalid token ID");
        ozNFT_B.ownerOf(tokenId);

        // can transfer token on srcChain as regular ERC721
        ozNFT_A.transferFrom(owner, alice, tokenId);
        assertEq(ozNFT_A.ownerOf(tokenId), alice);

        // approve the proxy to swap your token
        vm.startPrank(alice);
        ozNFT_A.approve(address(ozNFT_A), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            ozNFT_A.estimateSendFee(chainId_B, abi.encodePacked(alice), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        ozNFT_A.sendFrom{value: nativeFee}(
            alice, chainId_B, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );

        // token is burnt
        assertEq(ozNFT_A.ownerOf(tokenId), address(ozNFT_A));

        // token received on the dst chain
        assertEq(ozNFT_B.ownerOf(tokenId), alice);

        // estimate nativeFees
        (nativeFee,) = ozNFT_B.estimateSendFee(chainId_A, abi.encodePacked(alice), tokenId, false, defaultAdapterParams);

        // can send to other onft contract eg. not the original nft contract chain
        ozNFT_B.sendFrom{value: nativeFee}(
            alice, chainId_A, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );

        // token is burned on the sending chain
        assertEq(ozNFT_B.ownerOf(tokenId), address(ozNFT_B));
    }

    function test_Revert_SendTokenWhenNotOwner(address alice, uint256 tokenId) public {
        vm.assume(alice != address(0) && alice != address(this));

        ozNFT_A.mint(tokenId);
        address owner = ozNFT_A.owner();

        // approve the proxy to swap your token
        ozNFT_A.approve(address(ozNFT_A), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            ozNFT_A.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        ozNFT_A.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(ozNFT_B.ownerOf(tokenId), owner);

        // reverts because other address does not own it
        vm.expectRevert("ONFT721: send from incorrect owner");
        ozNFT_B.sendFrom(
            alice, chainId_A, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );
    }

    function test_SendFromOnBehalfOfAnotherUser(address alice, uint256 tokenId) public {
        vm.assume(alice != address(0) && alice != address(this));
        vm.deal(alice, 10 ether);

        ozNFT_A.mint(tokenId);
        address owner = ozNFT_A.owner();

        // approve the proxy to swap your token
        //ozNFT_A.approve(address(ozNFT_A), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            ozNFT_A.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        ozNFT_A.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(ozNFT_B.ownerOf(tokenId), owner);

        // approve the other user to send the token
        ozNFT_B.approve(address(alice), tokenId);

        // estimate nativeFees
        (nativeFee,) = ozNFT_B.estimateSendFee(chainId_A, abi.encodePacked(alice), tokenId, false, defaultAdapterParams);

        // sends across
        vm.prank(alice);
        ozNFT_B.sendFrom{value: nativeFee}(
            owner, chainId_A, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(ozNFT_A.ownerOf(tokenId), alice);
    }

    function test_Revert_SendFromWhenNotApproved(address alice, uint256 tokenId) public {
        vm.assume(alice != address(0) && alice != address(this));
        vm.deal(alice, 10 ether);

        ozNFT_A.mint(tokenId);
        address owner = ozNFT_A.owner();

        // approve the proxy to swap your token
        ozNFT_A.approve(address(ozNFT_A), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            ozNFT_A.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        ozNFT_A.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(ozNFT_B.ownerOf(tokenId), owner);

        // approve the contract to swap your token - should be alice
        ozNFT_B.approve(address(ozNFT_B), tokenId);

        // reverts because contract is approved, not the user
        vm.startPrank(alice);
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        ozNFT_B.sendFrom(
            owner, chainId_A, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );
    }

    function test_Revert_IfNotApprovedOnNonProxyChain(address alice, uint256 tokenId) public {
        vm.assume(alice != address(0) && alice != address(this));

        ozNFT_A.mint(tokenId);
        address owner = ozNFT_A.owner();

        // approve the proxy to swap your token
        ozNFT_A.approve(address(ozNFT_A), tokenId);

        // estimate nativeFees
        (uint256 nativeFee,) =
            ozNFT_A.estimateSendFee(chainId_B, abi.encodePacked(owner), tokenId, false, defaultAdapterParams);

        // swaps token to other chain
        ozNFT_A.sendFrom{value: nativeFee}(
            owner, chainId_B, abi.encodePacked(owner), tokenId, payable(owner), address(0), defaultAdapterParams
        );

        // token received on the dst chain
        assertEq(ozNFT_B.ownerOf(tokenId), owner);

        // reverts because user is not approved
        vm.startPrank(alice);
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        ozNFT_B.sendFrom(
            owner, chainId_A, abi.encodePacked(alice), tokenId, payable(alice), address(0), defaultAdapterParams
        );
    }

    function test_Revert_IfSenderDoesNotOwnToken(address alice, uint256 tokenId_A, uint256 tokenId_B) public {
        vm.assume(alice != address(0) && alice != address(this));
        vm.assume(tokenId_A != tokenId_B);

        address owner = ozNFT_A.owner();
        ozNFT_A.mint(tokenId_A);
        ozNFT_A.mint(tokenId_B);

        ozNFT_A.transferFrom(owner, alice, tokenId_B);

        // approve owner address to transfer, but not the other
        ozNFT_A.setApprovalForAll(address(ozNFT_A), true);

        // reverts because alice is not owner of tokenIdA
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        vm.startPrank(alice);
        ozNFT_A.sendFrom(
            alice, chainId_B, abi.encodePacked(alice), tokenId_A, payable(alice), address(0), defaultAdapterParams
        );

        // reverts because owner is not owner
        vm.expectRevert("ONFT721: send caller is not owner nor approved");
        ozNFT_A.sendFrom(
            alice, chainId_B, abi.encodePacked(owner), tokenId_A, payable(owner), address(0), defaultAdapterParams
        );
    }
}
