/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";

library ERC721Helper {
    /**
     * @notice  Functions for sending tokens that exist internally
     * @param   from    Address to send tokens to
     * @param   to      Address to receive the token
     * @param   tokenId Unique ID of the token to send
     */
    function transferFrom(address from, address to, uint256 tokenId) internal {
        assembly {
            // 현재 토큰 소유자 0x0에 저장
            mstore(0x0, sload(tokenId))

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(and(mload(0x00), 0xffffffffffffffffffffffffffffffffffffffff), from)) {
                mstore(0x0, Error_NotOwnedToken_Signature)
                revert(0x1c, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0x80, tokenId)
            mstore(0xa0, Slot_TokenAllowance)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))

            // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장한다.
            mstore(0xc0, from)
            mstore(0xe0, caller())
            mstore(0x100, Slot_OperatorApprovals)

            // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
            if iszero(or(or(eq(caller(), from), sload(keccak256(0xc0, 0x60))), eq(caller(), mload(0x80)))) {
                mstore(0x0, Error_NotOperaterable_Signature)
                revert(0x1c, 0x4)
            }

            // approved가 0 이라면 굳이 초기화 하진 않는다.
            if gt(mload(0x80), 0) { sstore(slot_ptr, 0x0) }

            // 토큰ID에 대한 새로운 소유자 정보 업데이트, 토큰 정보 확장필드 보존
            mstore(0x0c, shl(0x60, to))
            sstore(tokenId, mload(0x0))

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore8(0x80, Slot_OwnerInfo)
            let tmp_ptr := keccak256(0x80, 0x20)
            sstore(tmp_ptr, sub(sload(tmp_ptr), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x8c, shl(0x60, to))
            tmp_ptr := keccak256(0x80, 0x40)
            sstore(tmp_ptr, add(sload(tmp_ptr), 0x1))

            log4(0x0, 0x0, Event_Transfer_Signature, from, to, tokenId)
        }
    }

    /**
     * @notice  Returns the approved address that the token id has
     * @return  approved Address
     */
    function getApproved(uint256 tokenId) internal view returns (address) {
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
    function isApprovedForAll(address owner, address operator) internal view returns (bool) {
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
    function ownerOf(uint256 tokenId) internal view returns (address) {
        assembly {
            mstore(0x0, and(sload(tokenId), 0xffffffffffffffffffffffffffffffffffffffff))
            return(0x0, 0x20)
        }
    }

    /**
     * @notice  Takes an owner's address and returns the number of tokens that owner has.
     * @param   owner   Token owner
     * @return  Quantity owned
     */
    function balanceOf(address owner) external view returns (uint256) {
        assembly {
            mstore(BalanceOf_slot_ptr, owner)
            mstore8(BalanceOf_slot_ptr, Slot_OwnerInfo)
            mstore(BalanceOf_slot_ptr, and(sload(keccak256(BalanceOf_slot_ptr, 0x20)), 0xffffffffffffffff))
            return(BalanceOf_slot_ptr, BalanceOf_length)
        }
    }
}
