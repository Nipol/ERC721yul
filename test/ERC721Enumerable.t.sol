/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import { ERC721EnumerableMock as ERC721Enumerable, IERC721, IERC721Metadata, IERC165 } from "./ERC721EnumerableMock.sol";
import "../src/IERC721TokenReceiver.sol";
import "./Multicall3.sol";

contract Receiver is IERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public tid;
    bytes public data;

    function onERC721Received(address op, address fr, uint256 id, bytes calldata da) external returns (bytes4) {
        operator = op;
        from = fr;
        tid = id;
        data = da;
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

abstract contract ERC721EnumerableBed is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    Multicall3 public multicall;
    ERC721Enumerable public erc721e;
    address public receiver;
    address public wreceiver;
    address public rreceiver;
    address public alice = Address("alice");
    address public bob = Address("bob");
    address public charlie = Address("charlie");

    function setUp() public virtual {
        multicall = new Multicall3();
        erc721e = new ERC721Enumerable();
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

contract ERC721EnumerableDeployed is ERC721EnumerableBed {
    function setUp() public override {
        super.setUp();
    }

    function testSafeMintToReceiverContract() public {
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(address(0), receiver, 0);
        erc721e.safeMint(receiver, "deadbeef");
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);
        assertEq(erc721e.ownerOf(1), address(0));

        assertEq(Receiver(receiver).operator(), address(this));
        assertEq(Receiver(receiver).from(), address(0));
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), "deadbeef");
    }

    function testSafeMintToWrongReceiverContract() public {
        vm.expectRevert();
        erc721e.safeMint(wreceiver, "deadbeef");
        assertEq(erc721e.balanceOf(wreceiver), 0);
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testSafeMintToRevertReceiverContract() public {
        vm.expectRevert("Peek A Boo");
        erc721e.safeMint(rreceiver, "deadbeef");
        assertEq(erc721e.balanceOf(rreceiver), 0);
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testBulkSafeMintWith3TimesToReceiverContract() public {
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(address(0), receiver, 0);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(address(0), receiver, 1);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(address(0), receiver, 2);
        erc721e.safeMint(receiver, 3, "deadbeef");
        assertEq(erc721e.balanceOf(receiver), 3);
        assertEq(erc721e.ownerOf(0), receiver);
        assertEq(erc721e.ownerOf(1), receiver);
        assertEq(erc721e.ownerOf(2), receiver);
        assertEq(erc721e.ownerOf(3), address(0));

        assertEq(Receiver(receiver).operator(), address(this));
        assertEq(Receiver(receiver).from(), address(0));
        assertEq(Receiver(receiver).tid(), 2);
        assertEq(Receiver(receiver).data(), "deadbeef");
    }

    function testBulkMintWith3Times() public {
        erc721e.mint(alice, 3);
        assertEq(erc721e.balanceOf(alice), 3);
        assertEq(erc721e.ownerOf(0), alice);
        assertEq(erc721e.ownerOf(1), alice);
        assertEq(erc721e.ownerOf(2), alice);
        assertEq(erc721e.ownerOf(3), address(0));
    }

    function testBulkMintWith5Times() public {
        erc721e.mint(alice, 5);
        assertEq(erc721e.balanceOf(alice), 5);
        assertEq(erc721e.ownerOf(0), alice);
        assertEq(erc721e.ownerOf(1), alice);
        assertEq(erc721e.ownerOf(2), alice);
        assertEq(erc721e.ownerOf(3), alice);
        assertEq(erc721e.ownerOf(4), alice);
        assertEq(erc721e.ownerOf(5), address(0));
    }

    function testBulkMintWithConstantly() public {
        erc721e.mint(alice, 2);
        erc721e.mint(alice, 2);
        assertEq(erc721e.balanceOf(alice), 4);
        assertEq(erc721e.ownerOf(0), alice);
        assertEq(erc721e.ownerOf(1), alice);
        assertEq(erc721e.ownerOf(2), alice);
        assertEq(erc721e.ownerOf(3), alice);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721e.safeTransferFrom(alice, bob, 0, abi.encode(0x1234));
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testSafeTransferFrom() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721e.safeTransferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(address(this)), 0);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testTransferFrom() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721e.transferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721e.approve(bob, 0);
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testSetApprovalForAll() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, false, address(erc721e));
        emit ApprovalForAll(alice, bob, true);
        erc721e.setApprovalForAll(bob, true);
        assertEq(erc721e.isApprovedForAll(alice, bob), true);
    }

    function testSetApprovalForAllFromContract() public {
        vm.expectEmit(true, true, true, false, address(erc721e));
        emit ApprovalForAll(address(this), bob, true);
        erc721e.setApprovalForAll(bob, true);
        assertEq(erc721e.isApprovedForAll(address(this), bob), true);
    }

    function testGetApproved() public {
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testIsApprovedForAll() public {
        assertEq(erc721e.isApprovedForAll(alice, bob), false);
    }

    function testBalanceOf() public {
        assertEq(erc721e.balanceOf(alice), 0);
    }

    function testOwnerOf() public {
        assertEq(erc721e.ownerOf(0), address(0));
    }

    function testSupportInterfaces() public {
        assertEq(erc721e.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(erc721e.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(erc721e.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(erc721e.supportsInterface(0xDEADBEEF), false);
    }
}

contract ERC721EnumerableMinted is ERC721EnumerableBed {
    function setUp() public override {
        super.setUp();
        erc721e.mint(alice);
    }

    function testMulticallable() public {
        erc721e.mint(address(multicall));

        IMulticall3.Call memory cd1 = IMulticall3.Call({
            target: address(erc721e),
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

        assertEq(erc721e.balanceOf(alice), 2);
        assertEq(erc721e.balanceOf(address(multicall)), 0);
        assertEq(erc721e.ownerOf(1), alice);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, bob, 0);
        erc721e.safeTransferFrom(alice, bob, 0, "");
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(bob), 1);
        assertEq(erc721e.ownerOf(0), bob);
    }

    function testSafeTransferFromWithDataNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721e.safeTransferFrom(alice, bob, 0, "");
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);

        assertEq(Receiver(receiver).operator(), alice);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), cd);
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);

        assertEq(Receiver(receiver).operator(), alice);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), abi.encode("hello world"));
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(wreceiver), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(rreceiver), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testSafeTransferFrom() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, bob, 0);
        erc721e.safeTransferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(bob), 1);
        assertEq(erc721e.ownerOf(0), bob);
    }

    function testSafeTransferFromNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721e.safeTransferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);

        assertEq(Receiver(receiver).operator(), alice);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), "");
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(wreceiver), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(alice);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(rreceiver), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testTransferFrom() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, bob, 0);
        erc721e.transferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(bob), 1);
        assertEq(erc721e.ownerOf(0), bob);
    }

    function testTransferFromNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOperaterable()")));
        erc721e.transferFrom(alice, bob, 0);
        assertEq(erc721e.balanceOf(alice), 1);
        assertEq(erc721e.balanceOf(bob), 0);
        assertEq(erc721e.ownerOf(0), alice);
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Approval(alice, bob, 0);
        erc721e.approve(bob, 0);
        assertEq(erc721e.getApproved(0), bob);
    }

    function testBalanceOf() public {
        assertEq(erc721e.balanceOf(alice), 1);
    }

    function testOwnerOf() public {
        assertEq(erc721e.ownerOf(0), alice);
    }
}

contract ERC721EnumerableApprover is ERC721EnumerableBed {
    function setUp() public override {
        super.setUp();
        erc721e.mint(alice);
        vm.prank(alice);
        erc721e.approve(charlie, 0);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, charlie, 0);
        erc721e.safeTransferFrom(alice, charlie, 0, "");
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(charlie), 1);
        assertEq(erc721e.ownerOf(0), charlie);
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);
        assertEq(erc721e.getApproved(0), address(0));

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), cd);
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721e.getApproved(0), address(0));

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), abi.encode("hello world"));
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.getApproved(0), charlie);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.getApproved(0), charlie);
    }

    function testSafeTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, charlie, 0);
        erc721e.safeTransferFrom(alice, charlie, 0);
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721e.getApproved(0), address(0));

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), "");
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721e.getApproved(0), charlie);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721e.getApproved(0), charlie);
    }

    function testTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, bob, 0);
        erc721e.transferFrom(alice, bob, 0);
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testApprove() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Approval(alice, bob, 0);
        erc721e.approve(bob, 0);
        assertEq(erc721e.getApproved(0), bob);
    }

    function testGetApproved() public {
        assertEq(erc721e.getApproved(0), charlie);
    }
}

contract ERC721Operator is ERC721EnumerableBed {
    function setUp() public override {
        super.setUp();
        erc721e.mint(alice);
        vm.prank(alice);
        erc721e.setApprovalForAll(charlie, true);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, charlie, 0);
        erc721e.safeTransferFrom(alice, charlie, 0, "");
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(charlie), 1);
        assertEq(erc721e.ownerOf(0), charlie);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testFuzzSafeTransferFromWithData(bytes calldata cd) public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, cd);
        assertEq(erc721e.balanceOf(alice), 0);
        assertEq(erc721e.balanceOf(receiver), 1);
        assertEq(erc721e.ownerOf(0), receiver);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), cd);
    }

    function testSafeTransferFromWithDataToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0, abi.encode("hello world"));
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), abi.encode("hello world"));
    }

    function testSafeTransferFromWithDataToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromWithDataToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0, abi.encode("hello world"));
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, charlie, 0);
        erc721e.safeTransferFrom(alice, charlie, 0);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromToReceiverContract() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, receiver, 0);
        erc721e.safeTransferFrom(alice, receiver, 0);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);

        assertEq(Receiver(receiver).operator(), charlie);
        assertEq(Receiver(receiver).from(), alice);
        assertEq(Receiver(receiver).tid(), 0);
        assertEq(Receiver(receiver).data(), "");
    }

    function testSafeTransferFromToWrongReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert();
        erc721e.safeTransferFrom(alice, wreceiver, 0);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testSafeTransferFromToRevertReceiverContract() public {
        vm.prank(charlie);
        vm.expectRevert("Peek A Boo");
        erc721e.safeTransferFrom(alice, rreceiver, 0);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testTransferFrom() public {
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Transfer(alice, bob, 0);
        erc721e.transferFrom(alice, bob, 0);
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }

    function testApprove() public {
        assertEq(erc721e.getApproved(0), address(0));
        vm.prank(charlie);
        vm.expectEmit(true, true, true, true, address(erc721e));
        emit Approval(alice, bob, 0);
        erc721e.approve(bob, 0);
        assertEq(erc721e.getApproved(0), bob);
    }

    function testApproveNotFromOperator() public {
        assertEq(erc721e.getApproved(0), address(0));
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721e.approve(bob, 0);
        assertEq(erc721e.getApproved(0), address(0));
    }

    function testIsApprovedForAll() public {
        assertEq(erc721e.isApprovedForAll(alice, charlie), true);
    }
}
