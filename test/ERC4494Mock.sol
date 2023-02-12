/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "ERC721/ERC721.sol";
import "ERC721/extensions/ERC4494.sol";

contract ERC4494Mock is ERC4494, ERC721 {
    string public constant name = "NFT Permit";
    string public constant symbol = "NFT Permit";
    string public constant version = "1";
    string public constant baseURI = "ipfs://";

    constructor() ERC4494(name, version) { }

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function safeMint(address to, uint256 id, bytes calldata data) external {
        _mint(to, id);
        _receivercheck(address(0), to, id, data);
    }

    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId, ".json"));
    }
}
