/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";

contract ERC721Helper {
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

    /**
     * @notice  토큰 아이디가 가지고 있는 Approve된 주소를 반환합니다.
     * @return  approved 주소
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
     * @notice  토큰 소유자가 특정 오퍼레이터에게 토큰의 사용 권한을 이양했는지 확인합니다.
     * @param   owner       토큰 소유자
     * @param   operator    토큰 사용 대행자
     * @return  허용 여부
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
     * @notice  토큰의 소유자 주소를 반환하며, 소유자가 없는경우 zero address를 반환합니다.
     * @return  소유자 주소
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
     * @notice  소유자의 주소를 입력받아, 해당 소유자가 가지고 있는 토큰의 수량을 반환한다.
     * @param   owner   토큰 소유자
     * @return  소유하고 있는 수량
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
