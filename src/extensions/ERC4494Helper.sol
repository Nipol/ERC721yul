/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "ERC721/Constants.sol";

library ERC4494Helper {
    /**
     * @notice  Function that returns the nonce held by the token, used when configuring permit
     * @param   tokenId The NFT unique value for which you want to look up the nonce
     * @return  nonce Return as uint256
     */
    function nonces(uint256 tokenId) internal view returns (uint256) {
        assembly {
            mstore(0x0, shr(0xa0, sload(tokenId)))
            return(0x0, 0x20)
        }
    }
}
