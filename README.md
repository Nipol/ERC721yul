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

### Standard NFT (ERC721)
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

### NFT Permit (ERC4494)
Additionally, ERC4494 can be extended. To take advantage of this, you need a `version` of the contract in a string. and must also pass the `name` and `version` of the contract to the `constructor` area.

```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol";
import "ERC721/extensions/ERC4494.sol";

contract ERC4494Sample is ERC4494, ERC721 {
    string public constant name = "NFT Permit";
    string public constant symbol = "NFT Permit";
    string public constant version = "1";           // if isn`t there, this contract will not be compiled.
    string public constant baseURI = "ipfs://";

    // if isn`t there, this contract will not be compiled.
    constructor() ERC4494(name, version) { }

    // ... User spaces

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
| 944190                                          | 4744            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| approve                                         | 4722            | 23394  | 26764  | 28764  | 17      |
| balanceOf                                       | 567             | 1508   | 567    | 2567   | 51      |
| getApproved                                     | 363             | 1310   | 363    | 2363   | 19      |
| isApprovedForAll                                | 815             | 1672   | 815    | 2815   | 14      |
| mint(address)                                   | 51609           | 68311  | 68709  | 68709  | 43      |
| mint(address,uint256)                           | 49092           | 106050 | 104946 | 165216 | 4       |
| ownerOf                                         | 473             | 1273   | 473    | 2473   | 45      |
| safeMint(address,bytes)                         | 72219           | 72236  | 72226  | 72264  | 3       |
| safeMint(address,uint256,bytes)                 | 121877          | 121877 | 121877 | 121877 | 1       |
| safeTransferFrom(address,address,uint256)       | 2683            | 31368  | 35714  | 37621  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2999            | 31572  | 36078  | 37954  | 18      |
| setApprovalForAll                               | 24524           | 24524  | 24524  | 24524  | 15      |
| supportsInterface                               | 244             | 276    | 282    | 295    | 4       |
| transferFrom                                    | 2636            | 22411  | 33651  | 34346  | 5       |
```

```
| test/ERC4494Mock.sol:ERC4494Mock contract |                 |       |        |       |         |
|-------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                           | Deployment Size |       |        |       |         |
| 1158875                                   | 6041            |       |        |       |         |
| Function Name                             | min             | avg   | median | max   | # calls |
| DOMAIN_SEPARATOR                          | 310             | 310   | 310    | 310   | 7       |
| PERMIT_TYPEHASH                           | 288             | 288   | 288    | 288   | 7       |
| balanceOf                                 | 655             | 655   | 655    | 655   | 2       |
| getApproved                               | 363             | 363   | 363    | 363   | 2       |
| mint                                      | 68797           | 68797 | 68797  | 68797 | 7       |
| nonces                                    | 407             | 1962  | 2407   | 2407  | 9       |
| ownerOf                                   | 561             | 561   | 561    | 561   | 1       |
| permit                                    | 752             | 10643 | 4445   | 31402 | 7       |
| safeTransferFrom                          | 28459           | 28459 | 28459  | 28459 | 1       |
```
