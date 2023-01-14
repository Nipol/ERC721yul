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
| 965409                                          | 4850            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| approve                                         | 4729            | 23401  | 26771  | 28771  | 17      |
| balanceOf                                       | 574             | 1534   | 574    | 2574   | 50      |
| getApproved                                     | 370             | 1317   | 370    | 2370   | 19      |
| isApprovedForAll                                | 820             | 1677   | 820    | 2820   | 14      |
| mint(address)                                   | 51616           | 68318  | 68716  | 68716  | 43      |
| mint(address,uint256)                           | 117014          | 141122 | 141122 | 165230 | 2       |
| ownerOf                                         | 480             | 1358   | 480    | 2480   | 41      |
| safeMint(address,bytes)                         | 72226           | 72243  | 72233  | 72271  | 3       |
| safeMint(address,uint256,bytes)                 | 121884          | 121884 | 121884 | 121884 | 1       |
| safeTransferFrom(address,address,uint256)       | 2690            | 31375  | 35721  | 37628  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 3006            | 31579  | 36085  | 37961  | 18      |
| setApprovalForAll                               | 24531           | 24531  | 24531  | 24531  | 15      |
| supportsInterface                               | 246             | 278    | 284    | 297    | 4       |
| transferFrom                                    | 2643            | 22418  | 33656  | 34353  | 5       |
```

```
| test/ERC4494Mock.sol:ERC4494Mock contract |                 |       |        |       |         |
|-------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                           | Deployment Size |       |        |       |         |
| 1187513                                   | 6222            |       |        |       |         |
| Function Name                             | min             | avg   | median | max   | # calls |
| DOMAIN_SEPARATOR                          | 317             | 317   | 317    | 317   | 7       |
| PERMIT_TYPEHASH                           | 295             | 295   | 295    | 295   | 7       |
| balanceOf                                 | 662             | 662   | 662    | 662   | 2       |
| getApproved                               | 370             | 370   | 370    | 370   | 2       |
| mint                                      | 68804           | 68804 | 68804  | 68804 | 7       |
| nonces                                    | 414             | 1969  | 2414   | 2414  | 9       |
| ownerOf                                   | 568             | 568   | 568    | 568   | 1       |
| permit                                    | 759             | 11306 | 4458   | 33698 | 7       |
| safeTransferFrom                          | 28464           | 28464 | 28464  | 28464 | 1       |
```
