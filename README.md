# ERC721yul

Stack minimized ERC721 Implementations.

## TODO

- [x] bytes copy from calldata.
- [x] Diabled parameter, parse from calldata.
- [ ] constants memory space, and reuse.
- [ ] implement `safe~` reentrant safer.
- [ ] Optimize `onERC721Received`.
- [x] remove check zero address.
- [x] fuzz to calldata.
- [x] emit Event.


## Gas Usage
```
| test/ERC721Mock.sol:ERC721Mock contract         |                 |        |        |        |         |
|-------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |        |        |        |         |
| 751394                                          | 3781            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| approve                                         | 4723            | 23395  | 26765  | 28765  | 17      |
| balanceOf                                       | 574             | 1574   | 1574   | 2574   | 44      |
| getApproved                                     | 370             | 1317   | 370    | 2370   | 19      |
| isApprovedForAll                                | 776             | 1633   | 776    | 2776   | 14      |
| mint(address)                                   | 68710           | 68710  | 68710  | 68710  | 41      |
| mint(address,uint256)                           | 117023          | 141131 | 141131 | 165239 | 2       |
| ownerOf                                         | 474             | 1349   | 474    | 2474   | 32      |
| safeTransferFrom(address,address,uint256)       | 2660            | 31326  | 35668  | 37566  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2882            | 32577  | 35960  | 37822  | 17      |
| setApprovalForAll                               | 24487           | 24487  | 24487  | 24487  | 15      |
| supportsInterface                               | 246             | 278    | 284    | 297    | 4       |
| transferFrom                                    | 2616            | 22378  | 33616  | 34300  | 5       |
```