pragma solidity ^0.8.13;

import "../src/ERC721.sol";

contract ERC721Mock is ERC721 {
    string public constant name = "NFT NAME";
    string public constant symbol = "NFT SYMBOL";
    string public constant baseURI = "ipfs://";
    
    function mint(address to) external {
        _mint(to);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function safeMint(address to, bytes calldata data) external {
        _safemint(to, data);
    }

    function safeMint(address to, uint256 quantity, bytes calldata data) external {
        _safeMint(to, quantity, data);
    }

    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId, ".json"));
    }
}
