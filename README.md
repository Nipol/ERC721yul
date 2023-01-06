# ERC721yul

Gas minimized ERC721 Library Implementations.

## Installation

To install with [Foundry](https://github.com/gakonst/foundry):

```
forge install Nipol/ERC721yul
```

To install with [DappTools](https://github.com/dapphub/dapptools):

```
dapp install Nipol/ERC721yul
```


## Usage
The library is focused on providing the functions of ERC721. therefore, `name`, `symbol`, and `tokenURI` functions must be written by the developer. These are standard interfaces and must be implemented.

```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol";

contract ERC721Sample is ERC721 {
    string public constant name = "NFT NAME";
    string public constant symbol = "NFT SYMBOL";
    string public constant baseURI = "ipfs://";
    
    /// If you need to mint a token, you can use it as follows
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
```

## TODO

- [x] bytes copy from calldata.
- [x] Diabled parameter, parse from calldata.
- [ ] constants memory space, and reuse.
- [ ] Optimize `onERC721Received` call.
- [x] remove check zero address.
- [x] fuzz to calldata.
- [x] emit Event.
- [ ] Minimize storage key calculate
- [ ] Minimize name and symbol
- [ ] only yul


## Gas Usage
```
| test/ERC721Mock.sol:ERC721Mock contract         |                 |        |        |        |         |
|-------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |        |        |        |         |
| 914757                                          | 4597            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| approve                                         | 4723            | 23395  | 26765  | 28765  | 17      |
| balanceOf                                       | 574             | 1574   | 1574   | 2574   | 48      |
| getApproved                                     | 370             | 1317   | 370    | 2370   | 19      |
| isApprovedForAll                                | 820             | 1677   | 820    | 2820   | 14      |
| mint(address)                                   | 68710           | 68710  | 68710  | 68710  | 41      |
| mint(address,uint256)                           | 117023          | 141131 | 141131 | 165239 | 2       |
| ownerOf                                         | 474             | 1374   | 474    | 2474   | 40      |
| safeMint(address,bytes)                         | 72223           | 72240  | 72230  | 72268  | 3       |
| safeMint(address,uint256,bytes)                 | 121902          | 121902 | 121902 | 121902 | 1       |
| safeTransferFrom(address,address,uint256)       | 2660            | 31329  | 35671  | 37574  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2987            | 32677  | 36070  | 37927  | 17      |
| setApprovalForAll                               | 24531           | 24531  | 24531  | 24531  | 15      |
| supportsInterface                               | 246             | 278    | 284    | 297    | 4       |
| transferFrom                                    | 2616            | 22378  | 33616  | 34300  | 5       |
```
