pragma solidity ^0.8.13;

import "../src/ERC721.sol";

contract ERC721Mock is ERC721 {
    function mint(address to) external {
        _mint(to);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }
}
