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

contract ERC721Sample is ERC721 {
    function ... {
        uint256 balance = ERC721Helper.balanceOf(0x4Fe992E566F8a28248acC4cB401b7FfD7dF959B0);
    }
}
```

**Interfaces**
```solidity
/**
 * @notice  Functions for sending tokens that exist internally
 * @param   from    Address to send tokens to
 * @param   to      Address to receive the token
 * @param   tokenId Unique ID of the token to send
 */
function transferFrom(address from, address to, uint256 tokenId) internal {
```

```solidity
/**
 * @notice  Returns the approved address that the token id has
 * @return  approved Address
 */
function getApproved(uint256 tokenId) internal view returns (address);
```

```solidity
/**
 * @notice  Verify that the token owner has transferred the token's usage rights to a specific operator.
 * @param   owner       token owner
 * @param   operator    Token operator address
 * @return  Allowed or not
 */
function isApprovedForAll(address owner, address operator) internal view returns (bool);
```

```solidity
/**
 * @notice  Returns the address of the owner of the token, or zero address if there is no owner.
 * @return  Token owner
 */
function ownerOf(uint256 tokenId) internal view returns (address);
```

```solidity
/**
 * @notice  Takes an owner's address and returns the number of tokens that owner has.
 * @param   owner   Token owner
 * @return  Quantity owned
 */
function balanceOf(address owner) external view returns (uint256);
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

contract ERC721Sample is ERC721Enumerable {
    function ... {
        uint256 total = ERC721EnumerableHelper.totalSupply();
    }
}
```

**Interfaces**
```solidity
/**
 * @notice  Returns the total number of tokens currently issued.
 * @dev     This can be used to determine the next token number to be minted.
 * @return  Total number of tokens issued
 */
function totalSupply() internal view returns (uint256);
```

```solidity
/**
 * @notice  Sets the starting position when tokens are issued sequentially.
 * @dev     If you set that value to 100, the ID of the token will start at 100.
 * @param   initIndex   Unique ID of the token to use as a starting point
 */
function initialIndex(uint256 initIndex) internal;
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

contract ERC4494Sample is ERC4494, ERC721 {
    ...
    function ... {
        uint256 nonce = ERC4494Helper.nonces(11);
    }
}
```

**Interfaces**
```solidity
/**
 * @notice  Function that returns the nonce held by the token, used when configuring permit
 * @param   tokenId The NFT unique value for which you want to look up the nonce
 * @return  nonce Return as uint256
 */
function nonces(uint256 tokenId) internal view returns (uint256);
```

## Gas Usage
```
| test/ERC721Mock.sol:ERC721Mock contract         |                 |       |        |        |         |
|-------------------------------------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost                                 | Deployment Size |       |        |        |         |
| 776620                                          | 3907            |       |        |        |         |
| Function Name                                   | min             | avg   | median | max    | # calls |
| approve                                         | 4563            | 23238 | 26608  | 28608  | 17      |
| balanceOf                                       | 539             | 1427  | 539    | 2539   | 54      |
| getApproved                                     | 363             | 1310  | 363    | 2363   | 19      |
| isApprovedForAll                                | 739             | 1662  | 739    | 2739   | 13      |
| mint                                            | 471             | 45571 | 46552  | 46552  | 47      |
| ownerOf                                         | 410             | 1258  | 410    | 2410   | 33      |
| safeMint(address,uint256)                       | 49349           | 74113 | 74113  | 98878  | 2       |
| safeMint(address,uint256,bytes)                 | 785             | 75840 | 50135  | 185538 | 6       |
| safeTransferFrom(address,address,uint256)       | 2596            | 46713 | 37182  | 106317 | 14      |
| safeTransferFrom(address,address,uint256,bytes) | 2896            | 75111 | 37779  | 193144 | 18      |
| setApprovalForAll                               | 24454           | 24454 | 24454  | 24454  | 14      |
| supportsInterface                               | 244             | 276   | 282    | 295    | 4       |
| transferFrom                                    | 2549            | 22295 | 33545  | 34214  | 5       |
```

```
| test/ERC721EnumerableMock.sol:ERC721EnumerableMock contract |                 |        |        |        |         |
|-------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                             | Deployment Size |        |        |        |         |
| 916363                                                      | 4605            |        |        |        |         |
| Function Name                                               | min             | avg    | median | max    | # calls |
| approve                                                     | 4563            | 23238  | 26608  | 28608  | 17      |
| balanceOf                                                   | 627             | 1568   | 627    | 2627   | 51      |
| getApproved                                                 | 363             | 1310   | 363    | 2363   | 19      |
| isApprovedForAll                                            | 827             | 1684   | 827    | 2827   | 14      |
| mint(address)                                               | 51751           | 68453  | 68851  | 68851  | 43      |
| mint(address,uint256)                                       | 49012           | 105905 | 104833 | 164941 | 4       |
| ownerOf                                                     | 476             | 1276   | 476    | 2476   | 45      |
| safeMint(address,bytes)                                     | 52827           | 69231  | 52890  | 101977 | 3       |
| safeMint(address,uint256,bytes)                             | 173859          | 173859 | 173859 | 173859 | 1       |
| safeTransferFrom(address,address,uint256)                   | 2640            | 42491  | 37226  | 86461  | 14      |
| safeTransferFrom(address,address,uint256,bytes)             | 2984            | 71027  | 37867  | 173332 | 18      |
| setApprovalForAll                                           | 24542           | 24542  | 24542  | 24542  | 15      |
| supportsInterface                                           | 264             | 315    | 328    | 341    | 4       |
| transferFrom                                                | 2571            | 22317  | 33563  | 34236  | 5       |
```

```
| test/ERC4494Mock.sol:ERC4494Mock contract |                 |       |        |       |         |
|-------------------------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost                           | Deployment Size |       |        |       |         |
| 927435                                    | 4885            |       |        |       |         |
| Function Name                             | min             | avg   | median | max   | # calls |
| DOMAIN_SEPARATOR                          | 310             | 310   | 310    | 310   | 7       |
| PERMIT_TYPEHASH                           | 288             | 288   | 288    | 288   | 7       |
| balanceOf                                 | 627             | 627   | 627    | 627   | 2       |
| getApproved                               | 363             | 363   | 363    | 363   | 2       |
| mint                                      | 46618           | 46618 | 46618  | 46618 | 7       |
| nonces                                    | 344             | 1899  | 2344   | 2344  | 9       |
| ownerOf                                   | 498             | 498   | 498    | 498   | 1       |
| permit                                    | 730             | 10570 | 4348   | 31314 | 7       |
| safeTransferFrom                          | 28317           | 28317 | 28317  | 28317 | 1       |
```

## Donation
yoonsung.eth - 0x4Fe992E566F8a28248acC4cB401b7FfD7dF959B0