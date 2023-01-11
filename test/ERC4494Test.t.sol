// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ERC4494Mock.sol";

abstract contract ERC4494Bed is Test {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    ERC4494Mock nft;
    address public alice = Address("alice");
    address public bob = Address("bob");
    address public charlie = Address("charlie");

    function setUp() public virtual {
        nft = new ERC4494Mock();
        nft.mint(address(0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0));
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
        uint256 tokenId = 0;
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
        emit Approval(address(0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0), alice, 0);
        nft.permit(alice, tokenId, deadline, signature);

        assertEq(nft.nonces(tokenId), nonce + 1);
        assertEq(nft.getApproved(0), alice);
    }
}
