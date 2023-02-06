/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "./ERC4494Mock.sol";
import "./Multicall3.sol";

abstract contract ERC4494Bed is Test {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    Multicall3 public multicall;
    ERC4494Mock nft;
    address public alice = Address("alice");
    address public bob = Address("bob");
    address public charlie = Address("charlie");

    function setUp() public virtual {
        nft = new ERC4494Mock();
        multicall = new Multicall3();
        nft.mint(address(0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0), 721);
    }

    function Address(string memory name) internal returns (address ret) {
        ret = address(uint160(uint256(keccak256(abi.encode(name)))));
        vm.label(ret, name);
    }
}

contract ERC4494Test is ERC4494Bed {
    function testPermit() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, true, true);
        emit Approval(address(0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0), alice, tokenId);
        nft.permit(alice, tokenId, deadline, signature);

        assertEq(nft.nonces(tokenId), nonce + 1);
        assertEq(nft.getApproved(tokenId), alice);
    }

    function testMulticallable() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = address(multicall);
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        IMulticall3.Call memory cd1 = IMulticall3.Call({
            target: address(nft),
            callData: abi.encodeWithSignature(
                "permit(address,uint256,uint256,bytes)", address(multicall), tokenId, deadline, signature
                )
        });

        IMulticall3.Call memory cd2 = IMulticall3.Call({
            target: address(nft),
            callData: abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,bytes)",
                0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0,
                alice,
                tokenId,
                ""
                )
        });

        IMulticall3.Call[] memory cds = new IMulticall3.Call[](2);
        (cds[0], cds[1]) = (cd1, cd2);

        multicall.aggregate(cds);

        assertEq(nft.nonces(tokenId), nonce + 1);
        assertEq(nft.getApproved(tokenId), address(0));
        assertEq(nft.balanceOf(0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0), 0);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.ownerOf(tokenId), alice);
    }

    function testInvalidSignatureWithLength() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature = abi.encodePacked(r, s); // miss v

        vm.expectRevert(bytes4(keccak256("ERC4494_InvalidSignature()")));
        nft.permit(alice, tokenId, deadline, signature);
    }

    function testMalleabilitySignature() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature =
            abi.encodePacked(r, bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0), v); // change s

        vm.expectRevert(bytes4(keccak256("ERC4494_InvalidSignature()")));
        nft.permit(alice, tokenId, deadline, signature);
    }

    function testInvalidWrongSignature() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature = abi.encodePacked(
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
            v
        );

        vm.expectRevert(bytes4(keccak256("ERC4494_InvalidSignature()")));
        nft.permit(alice, tokenId, deadline, signature);
    }

    function testWrongOwner() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = type(uint256).max;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x5AEC774E6ae749DBB17A2EBA03648207A5bd7dDd sk
        (v, r, s) = vm.sign(0x50064dccbc8b9d9153e340ee2759b0fc4936ffe70cb451dad5563754d33c34a8, Hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(bytes4(keccak256("ERC4494_InvalidSignature()")));
        nft.permit(alice, tokenId, deadline, signature);
    }

    function testTimeout() public {
        bytes32 permit = nft.PERMIT_TYPEHASH();
        bytes32 domain = nft.DOMAIN_SEPARATOR();
        address spender = alice;
        uint256 tokenId = 721;
        uint256 deadline = 1;
        uint256 nonce = nft.nonces(tokenId);

        bytes32 Hash = keccak256(
            abi.encodePacked("\x19\x01", domain, keccak256(abi.encode(permit, spender, tokenId, nonce, deadline)))
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        // 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0 sk
        (v, r, s) = vm.sign(0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114, Hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(bytes4(keccak256("ERC4494_TimeOut()")));
        nft.permit(alice, tokenId, deadline, signature);
    }
}
