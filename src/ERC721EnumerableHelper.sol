/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";

contract ERC721EnumerableHelper {
    /**
     * @notice  Returns the total number of tokens currently issued.
     * @dev     This can be used to determine the next token number to be minted.
     * @return  Total number of tokens issued
     */
    function _totalSupply() internal view returns (uint256) {
        assembly {
            mstore(0x0, sload(Slot_TokenIndex))
            return(0x0, 0x20)
        }
    }

    /**
     * @notice  Sets the starting position when tokens are issued sequentially.
     * @dev     If you set that value to 100, the ID of the token will start at 100.
     * @param   initIndex   Unique ID of the token to use as a starting point
     */
    function _initialIndex(uint256 initIndex) internal {
        assembly {
            sstore(Slot_TokenIndex, initIndex)
        }
    }
}
