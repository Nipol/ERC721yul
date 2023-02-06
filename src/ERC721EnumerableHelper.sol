/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";

contract ERC721EnumerableHelper {
    /**
     * @notice  현재 발행되어 있는 토큰 수량을 반환합니다.
     * @dev     다음에 민팅될 토큰 번호로 사용할 수 있습니다.
     * @return  현재 발행된 토큰 수량
     */
    function _totalSupply() internal view returns (uint256) {
        assembly {
            mstore(0x0, sload(Slot_TokenIndex))
            return(0x0, 0x20)
        }
    }
}
