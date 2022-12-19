// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721.sol";
import "../src/IERC721TokenReceiver.sol";

contract Receiver is IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        view
        returns (bytes4)
    {
        console.log(_operator);
        console.log(_from);
        console.log(_tokenId);
        console.logBytes(_data);
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract WrongReceiver is IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        view
        returns (bytes4)
    {
        console.log(_operator);
        console.log(_from);
        console.log(_tokenId);
        console.logBytes(_data);
        return 0xBEEFDEAD;
    }
}

contract RevertReceiver is IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        view
        returns (bytes4)
    {
        console.log(_operator);
        console.log(_from);
        console.log(_tokenId);
        console.logBytes(_data);
        revert("Peek A Boo");
    }
}

abstract contract ERC721Bed is Test {
    ERC721 public erc721;
    address public receiver;
    address public wreceiver;
    address public rreceiver;

    function setUp() public virtual {
        erc721 = new ERC721();
        receiver = address(new Receiver());
        wreceiver = address(new WrongReceiver());
        rreceiver = address(new RevertReceiver());
    }
}

contract ERC721Deployed is ERC721Bed {
    function setUp() public override {
        super.setUp();
    }

    function testTransferFrom() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.transferFrom(address(this), address(0), 0);
    }

    function testSafeTransferFrom() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(address(this), address(0x1234), 0);
    }

    function testSafeTransferFromWithData() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(address(this), address(0x1234), 0, "");
    }

    function testSafeTransferFromWithReceiverContract() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(address(this), receiver, 0);
    }

    function testSafeTransferFromWithWrongReceiverContract() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(address(this), wreceiver, 0);
    }

    function testSafeTransferFromWithRevertReceiverContract() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.safeTransferFrom(address(this), rreceiver, 0);
    }

    function testApprove() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.approve(address(0x1234), 0);
    }

    function testSetApprovalForAll() public {
        erc721.setApprovalForAll(address(0x1234), true);
    }

    function testGetApproved() public {
        assertEq(erc721.getApproved(0), address(0));
    }

    function testIsApprovedForAll() public {
        assertEq(erc721.isApprovedForAll(address(this), address(0x1234)), false);
    }

    function testBalanceOf() public {
        assertEq(erc721.balanceOf(address(this)), 0);
    }

    function testOwnerOf() public {
        assertEq(erc721.ownerOf(0), address(0));
    }

    function testSupportInterfaces() public {
        assertEq(erc721.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(erc721.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(erc721.supportsInterface(type(IERC165).interfaceId), true);
    }
}

contract ERC721Minted is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(address(this));
    }

    function testTransferFrom() public {
        erc721.transferFrom(address(this), address(0), 0);
    }

    function testSafeTransferFrom() public {
        erc721.safeTransferFrom(address(this), address(0x1234), 0);
    }

    function testSafeTransferFromWithData() public {
        erc721.safeTransferFrom(address(this), address(0x1234), 0, "");
    }

    function testSafeTransferFromWithReceiverContract() public {
        erc721.safeTransferFrom(address(this), receiver, 0);
    }

    function testSafeTransferFromWithWrongReceiverContract() public {
        vm.expectRevert();
        erc721.safeTransferFrom(address(this), wreceiver, 0);
    }

    function testSafeTransferFromWithRevertReceiverContract() public {
        vm.expectRevert("Peek A Boo");
        erc721.safeTransferFrom(address(this), rreceiver, 0);
    }

    function testTransferFromNotFromOwner() public {
        vm.expectRevert(bytes4(keccak256("ERC721_NotOwnedToken()")));
        erc721.transferFrom(address(0x1234), address(0), 0);
    }

    function testApprove() public {
        erc721.approve(address(0x1234), 0);
    }

    function testBalanceOf() public {
        assertEq(erc721.balanceOf(address(this)), 1);
    }

    function testOwnerOf() public {
        assertEq(erc721.ownerOf(0), address(this));
    }
}

contract ERC721Approver is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(address(this));
        erc721.approve(address(0x1234), 0);
    }

    function testSafeTransferFrom() public {
        vm.prank(address(0x1234));
        erc721.safeTransferFrom(address(this), address(0x1234), 0);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(address(0x1234));
        erc721.safeTransferFrom(address(this), address(0x1234), 0, "");
    }

    function testTransferFrom() public {
        vm.prank(address(0x1234));
        erc721.transferFrom(address(this), address(0), 0);
    }

    function testGetApproved() public {
        assertEq(erc721.getApproved(0), address(0x1234));
    }
}

contract ERC721Operator is ERC721Bed {
    function setUp() public override {
        super.setUp();
        erc721.mint(address(this));
        erc721.setApprovalForAll(address(0x1234), true);
    }

    function testSafeTransferFrom() public {
        vm.prank(address(0x1234));
        erc721.safeTransferFrom(address(this), address(0x1234), 0);
    }

    function testSafeTransferFromWithData() public {
        vm.prank(address(0x1234));
        erc721.safeTransferFrom(address(this), address(0x1234), 0, "");
    }

    function testTransferFrom() public {
        vm.prank(address(0x1234));
        erc721.transferFrom(address(this), address(0), 0);
    }

    function testIsApprovedForAll() public {
        assertEq(erc721.isApprovedForAll(address(this), address(0x1234)), true);
    }
}
