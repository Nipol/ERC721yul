/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "ERC721/Constants.sol";

contract ERC4494Helper {
    /**
     * @notice  Function that returns the nonce held by the token, used when configuring permit
     * @param   tokenId The NFT unique value for which you want to look up the nonce
     * @return  nonce Return as uint256
     */
    function _nonces(uint256 tokenId) internal view returns (uint256) {
        assembly {
            mstore(0x20, Slot_TokenInfo)
            mstore(0x00, tokenId)
            mstore(0x00, shr(0xA0, sload(keccak256(0x00, 0x40))))
            return(0x00, 0x20)
        }
    }
}
