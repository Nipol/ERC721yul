/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";

contract ERC721Helper {
    /**
     * @notice  Returns the approved address that the token id has
     * @return  approved Address
     */
    function _getApproved(uint256 tokenId) internal view returns (address) {
        assembly {
            mstore(Approve_ptr, tokenId)
            mstore(Approve_next_ptr, Slot_TokenAllowance)
            mstore(Approve_ptr, and(sload(keccak256(Approve_ptr, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff))
            return(Approve_ptr, 0x20)
        }
    }

    /**
     * @notice  Verify that the token owner has transferred the token's usage rights to a specific operator.
     * @param   owner       Token owner
     * @param   operator    Token operator address
     * @return  Allowed or not
     */
    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        assembly {
            mstore(OperatorApproval_slot_ptr, Slot_OperatorApprovals)
            mstore(OperatorApproval_operator_ptr, operator)
            mstore(OperatorApproval_owner_ptr, owner)
            mstore(OperatorApproval_owner_ptr, sload(keccak256(OperatorApproval_owner_ptr, 0x60)))
            return(OperatorApproval_owner_ptr, 0x20)
        }
    }

    /**
     * @notice  Returns the address of the owner of the token, or zero address if there is no owner.
     * @return  Token owner
     */
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, Slot_TokenInfo)
            mstore(0x00, and(sload(keccak256(0x00, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff))
            return(0x00, 0x20)
        }
    }

    /**
     * @notice  Takes an owner's address and returns the number of tokens that owner has.
     * @param   owner   Token owner
     * @return  Quantity owned
     */
    function _balanceOf(address owner) external view returns (uint256) {
        assembly {
            mstore(BalanceOf_slot_ptr, owner)
            mstore(BalanceOf_next_slot_ptr, Slot_OwnerInfo)
            mstore(BalanceOf_slot_ptr, and(sload(keccak256(BalanceOf_slot_ptr, 0x40)), 0xffffffffffffffff))
            return(BalanceOf_slot_ptr, BalanceOf_length)
        }
    }
}
