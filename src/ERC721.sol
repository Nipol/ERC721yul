/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./Constants.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @title ERC721
 * @author yoonsung.eth
 * @dev 일반적으로 사용하는 방법에 맞춰 최적화한 NFT.
 */
abstract contract ERC721 is IERC721Metadata, IERC721, IERC165 {
    error ERC721_ExistedToken();

    error ERC721_NotOwnedToken();

    error ERC721_NotOperaterable();

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        external
        payable
        virtual
    {
        _transferFrom(from, to, tokenId);
        _receivercheck(from, to, tokenId, data);
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable virtual {
        _transferFrom(from, to, tokenId);
        _receivercheck(from, to, tokenId, "");
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function transferFrom(address from, address to, uint256 tokenId) external payable virtual {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @notice  토큰의 소유자가, approved에게 지정한 토큰에 대해 사용 권한을 부여합니다.
     * @param   approved    사용 권한을 부여할 주소
     * @param   tokenId     사용 권한을 부여할 토큰 아이디
     */
    function approve(address approved, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 정보
            mstore(Approve_ptr, tokenId)
            mstore(Approve_next_ptr, Slot_TokenInfo)
            mstore(
                Approve_Operator_owner_ptr,
                and(sload(keccak256(Approve_ptr, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff)
            )

            // 토큰 소유자가 허용한 오퍼레이터인지 확인
            mstore(Approve_Operator_operator_ptr, caller())
            mstore(Approve_Operator_slot_ptr, Slot_OperatorApprovals)

            switch or(
                sload(keccak256(Approve_Operator_owner_ptr, 0x60)), eq(caller(), mload(Approve_Operator_owner_ptr))
            )
            case true {
                mstore(Approve_ptr, tokenId)
                mstore(Approve_next_ptr, Slot_TokenAllowance)
                sstore(keccak256(Approve_ptr, 0x40), approved)
            }
            default {
                mstore(0x0, Error_NotOwnedToken_Signature)
                revert(0x1c, 0x4)
            }

            log4(0x0, 0x0, Event_Approval_Signature, mload(Approve_Operator_owner_ptr), approved, tokenId)
        }
    }

    /**
     * @notice  Operator에게 토큰의 소유자가 가진 모든 토큰에 대해 사용 권한을 부여합니다.
     * @param   operator    사용 권한을 부여할 주소
     * @param   approved    허용 여부
     */
    function setApprovalForAll(address operator, bool approved) external {
        assembly {
            mstore(OperatorApproval_slot_ptr, Slot_OperatorApprovals)
            mstore(OperatorApproval_operator_ptr, operator)
            mstore(OperatorApproval_owner_ptr, caller())
            sstore(keccak256(OperatorApproval_owner_ptr, 0x60), approved)

            mstore(0x0, approved)
            log3(0x0, 0x20, Event_ApprovalForAll_Signature, caller(), operator)
        }
    }

    /**
     * @notice  토큰 아이디가 가지고 있는 Approve된 주소를 반환합니다.
     * @return  approved 주소
     */
    function getApproved(uint256 tokenId) external view returns (address) {
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
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
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
    function ownerOf(uint256 tokenId) external view returns (address) {
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
    function balanceOf(address owner) external view returns (uint256) {
        assembly {
            mstore(BalanceOf_slot_ptr, owner)
            mstore(BalanceOf_next_slot_ptr, Slot_OwnerInfo)
            mstore(BalanceOf_slot_ptr, and(sload(keccak256(BalanceOf_slot_ptr, 0x40)), 0xffffffffffffffff))
            return(BalanceOf_slot_ptr, BalanceOf_length)
        }
    }

    function supportsInterface(bytes4 interfaceID) external pure virtual returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId
            || interfaceID == type(IERC165).interfaceId;
    }

    function tokenURI(uint256 tokenId) external pure virtual returns (string memory);

    /**
     * @notice  `from`이 가지고 있는 `tokenId`를 `to`에게 전송합니다.
     * @param   from    토큰을 가지고 있는 소유자 주소입니다. Operator가 아닌경우 `msg.sender`로 설정
     * @param   to      토큰을 수신받을 주소
     * @param   tokenId `from`이 `to`에게 보낼 토큰 고유 식별자
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        assembly {
            let freeptr := mload(0x40)

            // 현재 토큰 소유자 0xa0에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, Slot_TokenInfo)
            let tmp_ptr := keccak256(0x80, 0x40)
            mstore(0x00, sload(tmp_ptr))

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(and(mload(0x00), 0xffffffffffffffffffffffffffffffffffffffff), from)) {
                mstore(0x0, Error_NotOwnedToken_Signature)
                revert(0x1c, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
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

            // 토큰ID에 대한 새로운 소유자 정보 업데이트
            mstore(0x0c, shl(0x60, to))
            sstore(tmp_ptr, mload(0x00))

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, Slot_OwnerInfo)
            tmp_ptr := keccak256(0x80, 0x40)
            sstore(tmp_ptr, sub(sload(tmp_ptr), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x80, to)
            tmp_ptr := keccak256(0x80, 0x40)
            sstore(tmp_ptr, add(sload(tmp_ptr), 0x1))

            log4(0x0, 0x0, Event_Transfer_Signature, from, to, tokenId)

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`에게 `id` 토큰을 부여합니다.
     * @dev     해당 토큰이 이미 존재하는 경우 revert되어야 합니다.
     * @param   to 토큰을 받을 주소
     * @param   id 생성될 토큰의 아이디
     */
    function _mint(address to, uint256 id) internal virtual {
        assembly {
            let freeptr := mload(0x40)

            mstore(0x0, id)
            mstore(0x20, Slot_TokenInfo)
            let key := keccak256(0x0, 0x40)

            let info := sload(key)

            if iszero(info) {
                // 토큰 부여
                sstore(key, to)
                // 소유자 밸런스 증가
                mstore(0x0, to)
                mstore(0x20, Slot_OwnerInfo)
                let PoS := keccak256(0x0, 0x40)
                sstore(PoS, add(sload(PoS), 0x1))

                log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, id)
            }

            if info {
                mstore(0x0, Error_ExistedToken_Signature)
                revert(0x1c, 0x4)
            }

            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`가 컨트랙트인 경우`id` 및 `data`를 `IERC721TokenReceiver` 명세에 맞게 호출하여, 올바른 구현체인지 확인합니다.
     * @param   from    이전 토큰 소유자, mint되는 것이라면 0x0 주소로 설정되어야 합니다.
     * @param   to      토큰을 받는 대상의 주소
     * @param   id      토큰의 고유 아이디
     * @param   data    토큰을 받는 대상에게 넘길 데이터
     */
    function _receivercheck(address from, address to, uint256 id, bytes memory data) internal {
        assembly {
            let freeptr := mload(0x40)

            if extcodesize(to) {
                mstore(freeptr, TokenReceiver_Signature)
                mstore(add(freeptr, 0x04), caller())
                mstore(add(freeptr, 0x24), from)
                mstore(add(freeptr, 0x44), id)
                mstore(add(freeptr, 0x64), 0x0000000000000000000000000000000000000000000000000000000000000080)

                if iszero(mload(data)) {
                    mstore(add(freeptr, 0x84), 0x0000000000000000000000000000000000000000000000000000000000000000)
                }

                if gt(mload(data), 0) {
                    mstore(add(freeptr, 0x84), mload(data))
                    pop(
                        staticcall(
                            gas(),
                            0x04,
                            add(data, 0x20),
                            add(0x20, mload(data)),
                            add(freeptr, 0xa4),
                            add(0x20, mload(data))
                        )
                    )
                }

                if iszero(
                    and(
                        or(eq(mload(0x0), TokenReceiver_Signature), iszero(returndatasize())),
                        call(gas(), to, 0, freeptr, add(0x84, add(0x20, mload(data))), 0x0, 0x20)
                    )
                ) {
                    // revert case
                    let returnDataSize := returndatasize()
                    returndatacopy(0x0, 0x0, returnDataSize)
                    revert(0x0, returnDataSize)
                }
            }

            mstore(0x40, freeptr)
        }
    }
}
