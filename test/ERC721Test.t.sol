/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import { ERC721Mock as ERC721, IERC721, IERC721Metadata, IERC165 } from "./ERC721Mock.sol";
import "../src/IERC721TokenReceiver.sol";
import "./Multicall3.sol";

contract Receiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract WrongReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xBEEFDEAD;
    }
}

contract RevertReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        revert("Peek A Boo");
    }
}

abstract contract ERC721Bed is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    Multicall3 public multicall;
    ERC721 public erc721;
    address public receiver;
    address public wreceiver;
    address public rreceiver;
    address public alice = Address("alice");
    address public bob = Address("bob");
    address public charlie = Address("charlie");

    function setUp() public virtual {
        multicall = new Multicall3();
        erc721 = new ERC721();
        receiver = address(new Receiver());
        wreceiver = address(new WrongReceiver());
        rreceiver = address(new RevertReceiver());
        vm.label(receiver, "NFT Receiver");
        vm.label(wreceiver, "NFT Wronger");
        vm.label(rreceiver, "NFT Reverter");
    }

    function Address(string memory name) internal returns (address ret) {
        ret = address(uint160(uint256(keccak256(abi.encode(name)))));
        vm.label(ret, name);
    }
}

contract ERC721Deployed is ERC721Bed {
    function setUp() public override {
        super.setUp();
    }

    function testSafeMintToReceiverContract() public {
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(address(0), receiver, 0);
        erc721.safeMint(receiver, "deadbeef");
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
        assertEq(erc721.ownerOf(1), address(0));
    }

    function testSafeMintToWrongReceiverContract() public {
        vm.expectRevert();
        erc721.safeMint(wreceiver, "deadbeef");
        assertEq(erc721.balanceOf(wreceiver), 0);
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testSafeMintToRevertReceiverContract() public {
        vm.expectRevert("Peek A Boo");
        erc721.safeMint(rreceiver, "deadbeef");
        assertEq(erc721.balanceOf(rreceiver), 0);
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testBulkSafeMintWith3TimesToReceiverContract() public {
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(address(0), receiver, 0);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(address(0), receiver, 1);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(address(0), receiver, 2);
        erc721.safeMint(receiver, 3, "deadbeef");
        assertEq(erc721.balanceOf(receiver), 3);
        assertEq(erc721.ownerOf(0), receiver);
        assertEq(erc721.ownerOf(1), receiver);
        assertEq(erc721.ownerOf(2), receiver);
        assertEq(erc721.ownerOf(3), address(0));
    }

    function testBulkMintWith3Times() public {
        erc721.mint(alice, 3);
        assertEq(erc721.balanceOf(alice), 3);
        assertEq(erc721.ownerOf(0), alice);
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc721.ownerOf(2), alice);
        assertEq(erc721.ownerOf(3), address(0));
    }

    function testBulkMintWith5Times() public {
        erc721.mint(alice, 5);
        assertEq(erc721.balanceOf(alice), 5);
        assertEq(erc721.ownerOf(0), alice);
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc721.ownerOf(2), alice);
        assertEq(erc721.ownerOf(3), alice);
        assertEq(erc721.ownerOf(4), alice);
        assertEq(erc721.ownerOf(5), address(0));
    }

    function testBulkMintWithConstantly() public {
        erc721.mint(alice, 2);
        erc721.mint(alice, 2);
        assertEq(erc721.balanceOf(alice), 4);
        assertEq(erc721.ownerOf(0), alice);
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc721.ownerOf(2), alice);
        assertEq(erc721.ownerOf(3), alice);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(alice, bob, 0, abi.encode(0x1234));
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testSafeTransferFrom() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(address(this)), 0);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testTransferFrom() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.transferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.approve(bob, 0);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testSetApprovalForAll() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, false, address(erc721));
        emit ApprovalForAll(alice, bob, true);
        erc721.setApprovalForAll(bob, true);
        assertEq(erc721.isApprovedForAll(alice, bob), true);
    }

    function testSetApprovalForAllFromContract() public {
        vm.expectEmit(true, true, true, false, address(erc721));
        emit ApprovalForAll(address(this), bob, true);
        erc721.setApprovalForAll(bob, true);
        assertEq(erc721.isApprovedForAll(address(this), bob), true);
    }

    function testGetApproved() public {
        assertEq(erc721.getApproved(0), address(0));
    }

    function testIsApprovedForAll() public {
        assertEq(erc721.isApprovedForAll(alice, bob), false);
    }

    function testBalanceOf() public {
        assertEq(erc721.balanceOf(alice), 0);
    }

    function testOwnerOf() public {
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testSupportInterfaces() public {
        assertEq(erc721.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(erc721.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(erc721.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(erc721.supportsInterface(0xDEADBEEF), false);
    }
}

contract ERC721Minted is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(alice);
    }

    function testMulticallable() public {
        erc721.mint(address(multicall));

        IMulticall3.Call memory cd1 = IMulticall3.Call({
            target: address(erc721),
            callData: abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,bytes)",
                address(multicall),
                alice,
                1,
                "Hello world this is test for properly calldata parse."
                )
        });

        IMulticall3.Call[] memory cds = new IMulticall3.Call[](1);
        (cds[0]) = (cd1);

        multicall.aggregate(cds);

        assertEq(erc721.balanceOf(alice), 2);
        assertEq(erc721.balanceOf(address(multicall)), 0);
        assertEq(erc721.ownerOf(1), alice);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, bob, 0);
        erc721.safeTransferFrom(alice, bob, 0, "");
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(bob), 1);
        assertEq(erc721.ownerOf(0), bob);
    }

    function testSafeTransferFromWithDataNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721.safeTransferFrom(alice, bob, 0, "");
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(wreceiver), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(rreceiver), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testSafeTransferFrom() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, bob, 0);
        erc721.safeTransferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(bob), 1);
        assertEq(erc721.ownerOf(0), bob);
    }

    function testSafeTransferFromNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721.safeTransferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(wreceiver), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(rreceiver), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testTransferFrom() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, bob, 0);
        erc721.transferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(bob), 1);
        assertEq(erc721.ownerOf(0), bob);
    }

    function testTransferFromNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721.transferFrom(alice, bob, 0);
        assertEq(erc721.balanceOf(alice), 1);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.ownerOf(0), alice);
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Approval(alice, bob, 0);
        erc721.approve(bob, 0);
        assertEq(erc721.getApproved(0), bob);
    }

    function testBalanceOf() public {
        assertEq(erc721.balanceOf(alice), 1);
    }

    function testOwnerOf() public {
        assertEq(erc721.ownerOf(0), alice);
    }
}

contract ERC721Approver is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(alice);
        vm.prank(alice);
        erc721.approve(charlie, 0);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, charlie, 0);
        erc721.safeTransferFrom(alice, charlie, 0, "");
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(charlie), 1);
        assertEq(erc721.ownerOf(0), charlie);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721.getApproved(0), address(0));
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.getApproved(0), charlie);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.getApproved(0), charlie);
    }

    function testSafeTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, charlie, 0);
        erc721.safeTransferFrom(alice, charlie, 0);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721.getApproved(0), charlie);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721.getApproved(0), charlie);
    }

    function testTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, bob, 0);
        erc721.transferFrom(alice, bob, 0);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Approval(alice, bob, 0);
        erc721.approve(bob, 0);
        assertEq(erc721.getApproved(0), bob);
    }

    function testGetApproved() public {
        assertEq(erc721.getApproved(0), charlie);
    }
}

contract ERC721Operator is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(alice);
        vm.prank(alice);
        erc721.setApprovalForAll(charlie, true);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, charlie, 0);
        erc721.safeTransferFrom(alice, charlie, 0, "");
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(charlie), 1);
        assertEq(erc721.ownerOf(0), charlie);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721.balanceOf(alice), 0);
        assertEq(erc721.balanceOf(receiver), 1);
        assertEq(erc721.ownerOf(0), receiver);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, charlie, 0);
        erc721.safeTransferFrom(alice, charlie, 0);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, receiver, 0);
        erc721.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Transfer(alice, bob, 0);
        erc721.transferFrom(alice, bob, 0);
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }

    function testApprove() public {
        assertEq(erc721.getApproved(0), address(0));
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721));
        emit Approval(alice, bob, 0);
        erc721.approve(bob, 0);
        assertEq(erc721.getApproved(0), bob);
    }

    function testApproveNotFromOperator() public {
        assertEq(erc721.getApproved(0), address(0));
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.approve(bob, 0);
        assertEq(erc721.getApproved(0), address(0));
    }

    function testIsApprovedForAll() public {
        assertEq(erc721.isApprovedForAll(alice, charlie), true);
    }
}
