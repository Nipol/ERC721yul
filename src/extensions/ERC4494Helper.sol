/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "ERC721/Constants.sol";

contract ERC4494Helper {
    /**
     * @notice  NFT의 nonce를 반환하는 함수, permit를 구성할 때 사용
     * @param   tokenId nonce를 조회하고자 하는 NFT 아이디
     * @return  nonce uint256으로 반환
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
