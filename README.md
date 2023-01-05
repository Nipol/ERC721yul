# ERC721yul

Stack minimized ERC721 Implementations.

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
| 914957                                          | 4598            |        |        |        |         |
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
| safeTransferFrom(address,address,uint256)       | 2660            | 31331  | 35674  | 37577  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2987            | 32676  | 36070  | 37927  | 17      |
| setApprovalForAll                               | 24531           | 24531  | 24531  | 24531  | 15      |
| supportsInterface                               | 246             | 278    | 284    | 297    | 4       |
| transferFrom                                    | 2616            | 22378  | 33616  | 34300  | 5       |
```