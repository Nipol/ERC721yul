# ERC721yul

Solidity의 중간 언어인 yul을 이용하여 NFT 컨트랙트를 구현

## TODO

- [x] memcpy 구현.
- [x] Parameter 비활성화, calldata에서 직접 파싱
- [ ] 메모리 주소 constants 및 재사용
- [ ] safeTransferFrom reentrant safer
- [x] Check Zero address
- [x] fuzz to calldata
- [x] emit Event


## Gas Usage
```
| src/ERC721.sol:ERC721 contract                  |                 |       |        |       |         |
|-------------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                                 | Deployment Size |       |        |       |         |
| 799039                                          | 4019            |       |        |       |         |
| Function Name                                   | min             | avg   | median | max   | # calls |
| approve                                         | 4748            | 23423 | 26793  | 28793 | 17      |
| balanceOf                                       | 552             | 1599  | 2552   | 2552  | 42      |
| getApproved                                     | 364             | 1311  | 364    | 2364  | 19      |
| isApprovedForAll                                | 776             | 1633  | 776    | 2776  | 14      |
| mint                                            | 66798           | 66798 | 66798  | 66798 | 44      |
| ownerOf                                         | 458             | 1548  | 2458   | 2458  | 22      |
| safeTransferFrom(address,address,uint256)       | 466             | 29325 | 35751  | 37679 | 15      |
| safeTransferFrom(address,address,uint256,bytes) | 707             | 30892 | 36043  | 37970 | 18      |
| setApprovalForAll                               | 24487           | 24487 | 24487  | 24487 | 15      |
| supportsInterface                               | 246             | 278   | 284    | 297   | 4       |
| transferFrom                                    | 441             | 18788 | 20403  | 34418 | 6       |
```