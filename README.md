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
| src/ERC721.sol:ERC721 contract                  |                 |        |        |        |         |
|-------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |        |        |        |         |
| 751794                                          | 3783            |        |        |        |         |
| Function Name                                   | min             | avg    | median | max    | # calls |
| approve                                         | 4723            | 23398  | 26768  | 28768  | 17      |
| balanceOf                                       | 574             | 1597   | 2574   | 2574   | 43      |
| getApproved                                     | 370             | 1317   | 370    | 2370   | 19      |
| isApprovedForAll                                | 776             | 1633   | 776    | 2776   | 14      |
| mint(address)                                   | 68710           | 68710  | 68710  | 68710  | 41      |
| mint(address,uint256)                           | 165239          | 165239 | 165239 | 165239 | 1       |
| ownerOf                                         | 474             | 1402   | 474    | 2474   | 28      |
| safeTransferFrom(address,address,uint256)       | 2660            | 31326  | 35668  | 37566  | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2882            | 32577  | 35960  | 37822  | 17      |
| setApprovalForAll                               | 24487           | 24487  | 24487  | 24487  | 15      |
| supportsInterface                               | 246             | 278    | 284    | 297    | 4       |
| transferFrom                                    | 2616            | 22378  | 33616  | 34300  | 5       |
```