/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    string public constant name = "NFT NAME";
    string public constant symbol = "NFT SYMBOL";
    string public constant baseURI = "ipfs://";

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function safeMint(address to, uint256 id) external {
        _mint(to, id);
        _receivercheck(address(0), to, id, "");
    }

    function safeMint(address to, uint256 id, bytes calldata data) external {
        _mint(to, id);
        _receivercheck(address(0), to, id, data);
    }

    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId, ".json"));
    }
}
