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
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable virtual {
        _safeTransferFrom(from, to, tokenId);
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
                Approve_Operator_owner_ptr, and(sload(keccak256(Approve_ptr, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff)
            )

            // 토큰 소유자가 허용한 오퍼레이터인지 확인
            mstore(Approve_Operator_operator_ptr, caller())
            mstore(Approve_Operator_slot_ptr, Slot_OperatorApprovals)

            switch or(sload(keccak256(Approve_Operator_owner_ptr, 0x60)), eq(caller(), mload(Approve_Operator_owner_ptr)))
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

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId
            || interfaceID == type(IERC165).interfaceId;
    }

    function tokenURI(uint256 tokenId) external pure virtual returns (string memory);

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) internal {
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

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장.
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

            if gt(extcodesize(to), 0) {
                mstore(0x40, TokenReceiver_Signature)
                mstore(0x44, caller())
                mstore(0x64, from)
                mstore(0x84, tokenId)
                calldatacopy(0xa4, 0x64, sub(calldatasize(), 0x64))

                switch iszero(staticcall(gas(), to, 0x40, calldatasize(), 0x0, 0x20))
                case true {
                    // revert case
                    let returnDataSize := returndatasize()
                    returndatacopy(0x0, 0x0, returnDataSize)
                    revert(0x0, returnDataSize)
                }
                default {
                    // interface impl
                    returndatacopy(0x0, 0x0, 0x4)
                    if iszero(eq(mload(0x0), TokenReceiver_Signature)) { revert(0x0, 0x0) }
                }
            }

            log4(0x0, 0x0, Event_Transfer_Signature, from, to, tokenId)

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId) internal {
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

            if gt(extcodesize(to), 0) {
                mstore(0x40, TokenReceiver_Signature)
                mstore(0x44, caller())
                mstore(0x64, from)
                mstore(0x84, tokenId)
                mstore(0xc4, 0x0000000000000000000000000000000000000000000000000000000000000000)
                mstore(0xa4, 0x0000000000000000000000000000000000000000000000000000000000000080)

                // 4 + (32 * 5), 데이터 포지션 기록으로 인해 32 * 5 padding
                switch iszero(staticcall(gas(), to, 0x40, 0xa4, 0x0, 0x20))
                case true {
                    // revert case
                    let returnDataSize := returndatasize()
                    returndatacopy(0x0, 0x0, returnDataSize)
                    revert(0x0, returnDataSize)
                }
                default {
                    // interface implemented
                    returndatacopy(0x0, 0x0, 0x4)
                    if iszero(eq(mload(0x0), TokenReceiver_Signature)) { revert(0x0, 0x0) }
                }
            }

            log4(0x0, 0x0, Event_Transfer_Signature, from, to, tokenId)

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

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
     * @notice  `to`에게 하나의 토큰을 배포합니다.
     * @dev     스토리지 영역이 초기화되지 않았기 때문에, 초기 가스비용이 많이 소모된다.
     * @param   to 토큰을 받을 주소
     */
    function _mint(address to) internal {
        assembly {
            let freeptr := mload(0x40)

            // 소유자 밸런스 증가
            mstore(0x0, to)
            mstore(0x20, Slot_OwnerInfo)
            let PoS := keccak256(0x0, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 현재 토큰 카운터를 토큰 아이디로 사용하기 위해 메모리에 저장
            mstore(0x0, sload(Slot_TokenIndex))

            // 저장된 토큰 카운터에 해당하는 정보 저장.
            mstore(0x20, mload(0x0))
            mstore(0x40, Slot_TokenInfo)
            sstore(keccak256(0x20, 0x40), to)
            // 토큰 카운터 1증가
            sstore(Slot_TokenIndex, add(mload(0x0), 0x1))

            log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, mload(0x0))

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`에게 `quantity`만큼 토큰을 배포합니다.
     * @dev     스토리지 영역이 초기화되지 않았기 때문에, 초기 가스비용이 많이 소모된다.
     * @param   to          토큰을 받을 주소
     * @param   quantity    생성할 토큰 수량
     */
    function _mint(address to, uint256 quantity) internal {
        assembly {
            let freeptr := mload(0x40)

            // 0x00 현재 토큰 카운터
            mstore(0x0, sload(Slot_TokenIndex))
            mstore(0x20, add(mload(0x0), quantity))

            // 소유자 밸런스 증가
            mstore(0x40, to)
            mstore(0x60, Slot_OwnerInfo)
            let PoS := keccak256(0x40, 0x40)
            sstore(PoS, add(sload(PoS), quantity))

            for { let tokenId := mload(0x0) } iszero(eq(tokenId, mload(0x20))) { tokenId := add(tokenId, 0x01) } {
                // 저장된 토큰 카운터에 해당하는 정보 저장.
                mstore(0x40, tokenId)
                mstore(0x60, Slot_TokenInfo)
                sstore(keccak256(0x40, 0x40), to)
                log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, tokenId)
            }

            // 토큰 카운터 수량만큼 증가
            sstore(Slot_TokenIndex, mload(0x20))

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`에게 하나의 토큰을 배포합니다.
     * @dev     해당 함수에서는 마지막 인자로, to 주소로 넘길 데이터를 담아야 합니다.
     * @param   to 토큰을 받을 주소
     */
    function _safemint(address to, bytes calldata) internal {
        assembly {
            let freeptr := mload(0x40)

            // 소유자 밸런스 증가
            mstore(0x0, to)
            mstore(0x20, Slot_OwnerInfo)
            let PoS := keccak256(0x0, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 현재 토큰 카운터를 토큰 아이디로 사용하기 위해 메모리에 저장
            mstore(0x0, sload(Slot_TokenIndex))

            // 저장된 토큰 카운터에 해당하는 정보 저장.
            mstore(0x20, mload(0x0))
            mstore(0x40, Slot_TokenInfo)
            sstore(keccak256(0x20, 0x40), to)
            // 토큰 카운터 1증가
            sstore(Slot_TokenIndex, add(mload(0x0), 0x1))

            log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, mload(0x0))

            if gt(extcodesize(to), 0) {
                mstore(0x40, TokenReceiver_Signature)
                mstore(0x44, caller())
                mstore(0x64, 0x0)
                mstore(0x84, mload(0x0))
                mstore(0xa4, 0x0000000000000000000000000000000000000000000000000000000000000080)
                calldatacopy(0xc4, 0x44, sub(calldatasize(), 0x44))

                switch iszero(staticcall(gas(), to, 0x40, add(0x64, sub(calldatasize(), 0x24)), 0x0, 0x20))
                case true {
                    // revert case
                    let returnDataSize := returndatasize()
                    returndatacopy(0x0, 0x0, returnDataSize)
                    revert(0x0, returnDataSize)
                }
                default {
                    // interface impl
                    returndatacopy(0x0, 0x0, 0x4)
                    if iszero(eq(mload(0x0), TokenReceiver_Signature)) { revert(0x0, 0x0) }
                }
            }

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`에게 `quantity`만큼 토큰을 배포합니다.
     * @dev     해당 함수에서는 마지막 인자로, to 주소로 넘길 데이터를 담아야 합니다.
     * @param   to          토큰을 받을 주소
     */
    function _safeMint(address to, uint256 quantity, bytes calldata) internal {
        assembly {
            let freeptr := mload(0x40)

            // 0x00 현재 토큰 카운터
            mstore(0x0, sload(Slot_TokenIndex))
            // 0x20 더해진 최대 수량
            mstore(0x20, add(mload(0x0), quantity))

            // 소유자 밸런스 증가
            mstore(0x40, to)
            mstore(0x60, Slot_OwnerInfo)
            let PoS := keccak256(0x40, 0x40)
            sstore(PoS, add(sload(PoS), quantity))

            // to가 contract인가 아닌가
            mstore(0x40, gt(extcodesize(to), 0))

            for { let tokenId := mload(0x0) } iszero(eq(tokenId, mload(0x20))) { tokenId := add(tokenId, 0x1) } {
                // 저장된 토큰 카운터에 해당하는 정보 저장.
                mstore(0x60, tokenId)
                mstore(0x80, Slot_TokenInfo)
                sstore(keccak256(0x60, 0x40), to)
                log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, tokenId)

                if mload(0x40) {
                    mstore(0x60, TokenReceiver_Signature)
                    mstore(0x64, caller())
                    mstore(0x84, 0x0)
                    mstore(0xa4, tokenId)
                    mstore(0xc4, 0x0000000000000000000000000000000000000000000000000000000000000080)
                    calldatacopy(0xe4, 0x64, sub(calldatasize(), 0x64))

                    switch iszero(staticcall(gas(), to, 0x60, add(0x84, sub(calldatasize(), 0x64)), 0x0, 0x20))
                    case true {
                        // revert case
                        let returnDataSize := returndatasize()
                        returndatacopy(0x0, 0x0, returnDataSize)
                        revert(0x0, returnDataSize)
                    }
                    default {
                        // interface impl
                        returndatacopy(0x0, 0x0, 0x4)
                        if iszero(eq(mload(0x0), TokenReceiver_Signature)) { revert(0x0, 0x0) }
                    }
                }
            }

            // 토큰 카운터 수량만큼 증가
            sstore(Slot_TokenIndex, mload(0x20))

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }
}
