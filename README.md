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
The library is focused on providing the functions of ERC721. therefore, `name`, `symbol`, and `tokenURI` functions must be written by the developer. These are standard interfaces and must be implemented. In the example below, injecting a token ID, but you need to create a token ID generation logic.

With this library, you have access to three mint functions. These functions require you to specify the IDs of the newly created NFTs.

In particular, if you implement a function with the `safe` prefix, you should put `_receivercheck()` at the end of the function. See the example below.

**Usage**
```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol";

contract ERC721Sample is ERC721 {
    string public constant name = "NFT NAME";
    string public constant symbol = "NFT SYMBOL";
    string public constant baseURI = "ipfs://";
    
    /// If you need to mint a token, you can use it as follows
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
```

#### Standard NFT Helper
The library is accessing the storage directly through the slot. However, it is common to be unfamiliar with this, so we provide a set of helper functions.

The default library consists of all external functions and the required internal functions. The helpers are a set of functions to aid in development.

**Usage**
```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol";
import "ERC721/ERC721Helper.sol";

contract ERC721Sample is ERC721, ERC721Helper {
    ...
}
```

**Interfaces**
```solidity
/**
 * @notice  Returns the approved address that the token id has
 * @return  approved Address
 */
function _getApproved(uint256 tokenId) internal view returns (address);
```

```solidity
/**
 * @notice  Verify that the token owner has transferred the token's usage rights to a specific operator.
 * @param   owner       token owner
 * @param   operator    Token operator address
 * @return  Allowed or not
 */
function _isApprovedForAll(address owner, address operator) internal view returns (bool);
```

```solidity
/**
 * @notice  Returns the address of the owner of the token, or zero address if there is no owner.
 * @return  Token owner
 */
function _ownerOf(uint256 tokenId) internal view returns (address);
```

```solidity
/**
 * @notice  Takes an owner's address and returns the number of tokens that owner has.
 * @param   owner   Token owner
 * @return  Quantity owned
 */
function _balanceOf(address owner) external view returns (uint256);
```

### Enumerable NFT (ERC721Enumerable)
The library is focused on providing the functions of ERC721Enumerable. therefore, `name`, `symbol`, and `tokenURI` functions must be written by the developer. These are standard interfaces and must be implemented. In the example below, every token id starts at 0 and gives an incremented token id, one for each `mint` call.

```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721Enumerable.sol";

contract ERC721Sample is ERC721Enumerable {
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
        _safeMint(to, data);
    }

    function safeMint(address to, uint256 quantity, bytes calldata data) external {
        _safeMint(to, quantity, data);
    }

    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId, ".json"));
    }
}
```

#### Enumerable NFT Helper
**Usage**
```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721Enumerable.sol";
import "ERC721/ERC721EnumerableHelper.sol";

contract ERC721Sample is ERC721Enumerable, ERC721EnumerableHelper {
    ...
}
```

**Interfaces**
```solidity
/**
 * @notice  Returns the total number of tokens currently issued.
 * @dev     This can be used to determine the next token number to be minted.
 * @return  Total number of tokens issued
 */
function _totalSupply() internal view returns (uint256);
```

```solidity
/**
 * @notice  Sets the starting position when tokens are issued sequentially.
 * @dev     If you set that value to 100, the ID of the token will start at 100.
 * @param   initIndex   Unique ID of the token to use as a starting point
 */
function _initialIndex(uint256 initIndex) internal;
```

### NFT Permit (ERC4494)
Additionally, ERC4494 can be extended. To take advantage of this, you need a `version` of the contract in a string. and must also pass the `name` and `version` of the contract to the `constructor` area. These extensions are applicable to both typical and Enumerable implementations.

```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol"; // or ERC721Enumerable
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

#### NFT Permit Helper

**Usage**
```solidity
pragma solidity ^0.8.17;

import "ERC721/ERC721.sol"; // or ERC721Enumerable
import "ERC721/extensions/ERC4494.sol";
import "ERC721/extensions/ERC4494Helper.sol";

contract ERC4494Sample is ERC4494, ERC721, ERC4494Helper {
    ...
}
```

**Interfaces**
```solidity
/**
 * @notice  Function that returns the nonce held by the token, used when configuring permit
 * @param   tokenId The NFT unique value for which you want to look up the nonce
 * @return  nonce Return as uint256
 */
function _nonces(uint256 tokenId) internal view returns (uint256);
```


## TODO

- [x] bytes copy from calldata.
- [x] Diabled parameter, parse from calldata.
- [x] constants memory space, and reuse.
- [x] Optimize `onERC721Received` call.
- [x] remove check zero address.
- [x] fuzz to calldata.
- [x] emit Event.
- [x] Minimize storage key calculate
- [ ] Minimize name and symbol
- [ ] only yul


## Gas Usage
```
| test/ERC721Mock.sol:ERC721Mock contract         |                 |       |        |        |         |
|-------------------------------------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |       |        |        |         |
| 828272                                          | 4165            |       |        |        |         |
| Function Name                                   | min             | avg   | median | max    | # calls |
| approve                                         | 4662            | 23329 | 26698  | 28698  | 17      |
| balanceOf                                       | 545             | 1433  | 545    | 2545   | 54      |
| getApproved                                     | 363             | 1310  | 363    | 2363   | 19      |
| isApprovedForAll                                | 739             | 1662  | 739    | 2739   | 13      |
| mint                                            | 539             | 45644 | 46625  | 46625  | 47      |
| ownerOf                                         | 473             | 1321  | 473    | 2473   | 33      |
| safeMint(address,uint256)                       | 49573           | 74400 | 74400  | 99227  | 2       |
| safeMint(address,uint256,bytes)                 | 829             | 68919 | 50721  | 141797 | 6       |
| safeTransferFrom(address,address,uint256)       | 2683            | 46025 | 35645  | 106390 | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2977            | 74593 | 35995  | 193221 | 18      |
| setApprovalForAll                               | 24454           | 24454 | 24454  | 24454  | 14      |
| supportsInterface                               | 244             | 276   | 282    | 295    | 4       |
| transferFrom                                    | 2633            | 22369 | 33608  | 34292  | 5       |
```

```
| test/ERC721EnumerableMock.sol:ERC721EnumerableMock contract |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                             | Deployment Size |        |        |        |         |
| 949396                                                      | 4770            |        |        |        |         |
| Function Name                                               | min             | avg    | median | max    | # calls |
| approve                                                     | 4662            | 23329  | 26698  | 28698  | 17      |
| balanceOf                                                   | 633             | 1574   | 633    | 2633   | 51      |
| getApproved                                                 | 363             | 1310   | 363    | 2363   | 19      |
| isApprovedForAll                                            | 827             | 1684   | 827    | 2827   | 14      |
| mint(address)                                               | 51855           | 68557  | 68955  | 68955  | 43      |
| mint(address,uint256)                                       | 49181           | 106139 | 105035 | 165305 | 4       |
| ownerOf                                                     | 539             | 1339   | 539    | 2539   | 45      |
| safeMint(address,bytes)                                     | 52905           | 69312  | 52968  | 102063 | 3       |
| safeMint(address,uint256,bytes)                             | 174059          | 174059 | 174059 | 174059 | 1       |
| safeTransferFrom(address,address,uint256)                   | 2727            | 41803  | 35689  | 86534  | 14      |
| safeTransferFrom(address,address,uint256,bytes)             | 3065            | 70509  | 36083  | 173409 | 18      |
| setApprovalForAll                                           | 24542           | 24542  | 24542  | 24542  | 15      |
| supportsInterface                                           | 264             | 315    | 328    | 341    | 4       |
| transferFrom                                                | 2655            | 22390  | 33625  | 34314  | 5       |
```

```
| test/ERC4494Mock.sol:ERC4494Mock contract |                 |       |        |       |         |
|-------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                           | Deployment Size |       |        |       |         |
| 985694                                    | 5176            |       |        |       |         |
| Function Name                             | min             | avg   | median | max   | # calls |
| DOMAIN_SEPARATOR                          | 310             | 310   | 310    | 310   | 7       |
| PERMIT_TYPEHASH                           | 288             | 288   | 288    | 288   | 7       |
| balanceOf                                 | 633             | 633   | 633    | 633   | 2       |
| getApproved                               | 363             | 363   | 363    | 363   | 2       |
| mint                                      | 46691           | 46691 | 46691  | 46691 | 7       |
| nonces                                    | 407             | 1962  | 2407   | 2407  | 9       |
| ownerOf                                   | 561             | 561   | 561    | 561   | 1       |
| permit                                    | 730             | 10621 | 4423   | 31380 | 7       |
| safeTransferFrom                          | 28368           | 28368 | 28368  | 28368 | 1       |
```
