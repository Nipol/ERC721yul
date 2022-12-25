/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.13;

import "./Constants.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

/**
 * @title ERC721
 * @author yoonsung.eth
 * @dev 일반적으로 사용하는 방법에 맞춰 최적화한 NFT.
 */
contract ERC721 is IERC721Metadata, IERC721, IERC165 {
    error ERC721_NotOwnedToken();

    error ERC721_NotOperaterable();

    error ERC721_NotAllowedZeroAddress();

    string public constant name = "NFT NAME";
    string public constant symbol = "NFT SYMBOL";
    string public constant baseURI = "ipfs://";
    uint256 private tokenIndex;

    // token information
    /**
     *  slot map
     *    3                   2                   1                   0
     *  2 1 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
     * ┌───────────────────────┬───────────────────────────────────────┐
     * │       Future Use      │              Owner Address            │
     * └───────────────────────┴───────────────────────────────────────┘
     */
    mapping(uint256 => uint256) private tokenInfo;

    // address information(not yet)
    /**
     *  slot map
     *    3                   2                   1                   0
     *  2 1 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
     * ┌─────────────────────────────────────────────┬─────────────────┐
     * │       Future Use                            │     balances    │
     * └─────────────────────────────────────────────┴─────────────────┘
     */
    mapping(address => uint256) private ownerInfo;
    mapping(uint256 => address) private tokenAllowance;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    constructor() { }

    /**
     * @notice  `to`에게 하나의 토큰을 배포합니다.
     * @dev     스토리지 영역이 초기화되지 않았기 때문에, 초기 가스비용이 많이 소모된다.
     * @param   to 토큰을 받을 주소
     */
    function mint(address to) external {
        assembly {
            // 소유자 밸런스 증가
            mstore(0x0, to)
            mstore(0x20, ownerInfo.slot)
            let PoS := keccak256(0x0, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 현재 토큰 카운터를 토큰 아이디로 사용하기 위해 메모리에 저장
            mstore(0x0, sload(tokenIndex.slot))

            // 저장된 토큰 카운터에 해당하는 정보 저장.
            mstore(0x20, mload(0x0))
            mstore(0x40, tokenInfo.slot)
            sstore(keccak256(0x20, 0x40), to)
            // 토큰 카운터 1증가
            sstore(tokenIndex.slot, add(mload(0x0), 0x1))

            log4(0x0, 0x0, Event_Approval_Signature, 0x0, calldataload(0x4), add(mload(0x0), 0x1))
        }
    }

    /**
     * @notice  `to`에게 `quantity`만큼 토큰을 배포합니다.
     * @dev     스토리지 영역이 초기화되지 않았기 때문에, 초기 가스비용이 많이 소모된다.
     * @param   to          토큰을 받을 주소
     * @param   quantity    생성할 토큰 수량
     */
    function mint(address to, uint256 quantity) external {
        assembly {
            // 0x00 현재 토큰 카운터
            mstore(0x20, add(mload(0x0), quantity))
            mstore(0x0, sload(tokenIndex.slot))

            // 소유자 밸런스 증가
            mstore(0x40, to)
            mstore(0x60, ownerInfo.slot)
            let PoS := keccak256(0x40, 0x40)
            sstore(PoS, add(sload(PoS), quantity))

            for { let tokenId := mload(0x0) } iszero(eq(tokenId, mload(0x20))) { tokenId := add(tokenId, 0x1) } {
                // 저장된 토큰 카운터에 해당하는 정보 저장.
                mstore(0x40, tokenId)
                mstore(0x60, tokenInfo.slot)
                sstore(keccak256(0x40, 0x40), to)
                log4(0x0, 0x0, Event_Approval_Signature, 0x0, calldataload(0x4), tokenId)
            }

            // 토큰 카운터 수량만큼 증가
            sstore(tokenIndex.slot, mload(0x20))
        }
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external payable {
        assembly {
            // 현재 토큰 소유자 0xa0에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let tmp_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(sload(tmp_ptr), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))

            // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장한다.
            mstore(0xc0, from)
            mstore(0xe0, operatorApprovals.slot)
            mstore(0xe0, keccak256(0xc0, 0x40))
            mstore(0xc0, caller())
            mstore(0xc0, sload(keccak256(0xc0, 0x40)))

            // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
            if iszero(or(or(eq(caller(), from), mload(0xc0)), eq(caller(), mload(0x80)))) {
                mstore(0x80, Error_NotOperaterable_Signature)
                revert(0x80, 0x4)
            }

            // approved가 0 이라면 굳이 초기화 하진 않는다.
            if gt(mload(0x80), 0) { sstore(slot_ptr, 0x0) }

            // 토큰ID에 대한 새로운 소유자 정보 업데이트
            sstore(tmp_ptr, to)

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
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

                switch iszero(staticcall(gas(), to, 0x40, add(0x64, sub(calldatasize(), 0x64)), 0x0, 0x20))
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
        }
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 0xa0에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let tmp_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(sload(tmp_ptr), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))

            // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장한다.
            mstore(0xc0, from)
            mstore(0xe0, operatorApprovals.slot)
            mstore(0xe0, keccak256(0xc0, 0x40))
            mstore(0xc0, caller())
            mstore(0xc0, sload(keccak256(0xc0, 0x40)))

            // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
            if iszero(or(or(eq(caller(), from), mload(0xc0)), eq(caller(), mload(0x80)))) {
                mstore(0x80, Error_NotOperaterable_Signature)
                revert(0x80, 0x4)
            }

            // approved가 0 이라면 굳이 초기화 하진 않는다.
            if gt(mload(0x80), 0) { sstore(slot_ptr, 0x0) }

            // 토큰ID에 대한 새로운 소유자 정보 업데이트
            sstore(tmp_ptr, to)

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
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
                mstore(0xa4, 0x0000000000000000000000000000000000000000000000000000000000000040)

                // 4 + (32 * 5) + 1, 데이터 포지션 기록으로 인해 32 + 1bytes padding
                switch iszero(staticcall(gas(), to, 0x40, 0xa5, 0x0, 0x20))
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
        }
    }

    /**
     * @notice  토큰을 가지고 있는 from 주소로 부터, to 주소에게 토큰을 전송합니다.
     * @param   from    토큰 소유자 주소
     * @param   to      토큰 수신자 주소
     * @param   tokenId 전송할 토큰의 ID
     */
    function transferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 0xa0에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let tmp_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(sload(tmp_ptr), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))

            // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장한다.
            mstore(0xc0, from)
            mstore(0xe0, operatorApprovals.slot)
            mstore(0xe0, keccak256(0xc0, 0x40))
            mstore(0xc0, caller())
            mstore(0xc0, sload(keccak256(0xc0, 0x40)))

            // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
            if iszero(or(or(eq(caller(), from), mload(0xc0)), eq(caller(), mload(0x80)))) {
                mstore(0x80, Error_NotOperaterable_Signature)
                revert(0x80, 0x4)
            }

            // approved가 0 이라면 굳이 초기화 하진 않는다.
            if gt(mload(0x80), 0) { sstore(slot_ptr, 0x0) }

            // 토큰ID에 대한 새로운 소유자 정보 업데이트
            sstore(tmp_ptr, to)

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
            tmp_ptr := keccak256(0x80, 0x40)
            sstore(tmp_ptr, sub(sload(tmp_ptr), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x80, to)
            tmp_ptr := keccak256(0x80, 0x40)
            sstore(tmp_ptr, add(sload(tmp_ptr), 0x1))

            log4(0x0, 0x0, Event_Transfer_Signature, from, to, tokenId)
        }
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
            mstore(Approve_next_ptr, tokenInfo.slot)
            mstore(Approve_Owner_ptr, sload(keccak256(Approve_ptr, 0x40)))

            // 토큰 소유자가 허용한 오퍼레이터인지 확인
            mstore(Approve_Operator_ptr, mload(Approve_Owner_ptr))
            mstore(Approve_Operator_next_ptr, operatorApprovals.slot)
            mstore(Approve_Operator_next_ptr, keccak256(Approve_Operator_ptr, 0x40))
            mstore(Approve_Operator_ptr, caller())
            mstore(Approve_Operator_ptr, sload(keccak256(Approve_Operator_ptr, 0x40)))

            switch or(eq(caller(), mload(Approve_Owner_ptr)), mload(Approve_Operator_ptr))
            case true {
                mstore(Approve_ptr, tokenId)
                mstore(Approve_next_ptr, tokenAllowance.slot)
                sstore(keccak256(Approve_ptr, 0x40), approved)
            }
            default {
                mstore(0x40, Error_NotOwnedToken_Signature)
                revert(0x40, 0x4)
            }

            log4(0x0, 0x0, Event_Approval_Signature, mload(Approve_Owner_ptr), approved, tokenId)
        }
    }

    /**
     * @notice  Operator에게 토큰의 소유자가 가진 모든 토큰에 대해 사용 권한을 부여합니다.
     * @param   operator    사용 권한을 부여할 주소
     * @param   approved    허용 여부
     */
    function setApprovalForAll(address operator, bool approved) external {
        assembly {
            mstore(OperatorApproval_ptr, caller())
            mstore(OperatorApproval_next_ptr, operatorApprovals.slot)
            mstore(OperatorApproval_next_ptr, keccak256(OperatorApproval_ptr, 0x40))
            mstore(OperatorApproval_ptr, operator)
            sstore(keccak256(OperatorApproval_ptr, 0x40), approved)

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
            mstore(Approve_next_ptr, tokenAllowance.slot)
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
            mstore(OperatorApproval_ptr, owner)
            mstore(OperatorApproval_next_ptr, operatorApprovals.slot)
            mstore(OperatorApproval_next_ptr, keccak256(OperatorApproval_ptr, 0x40))
            mstore(OperatorApproval_ptr, operator)
            mstore(OperatorApproval_ptr, sload(keccak256(OperatorApproval_ptr, 0x40)))
            return(OperatorApproval_ptr, 0x20)
        }
    }

    /**
     * @notice  토큰의 소유자 주소를 반환하며, 소유자가 없는경우 zero address를 반환합니다.
     * @return  소유자 주소
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, tokenInfo.slot)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return(0x00, 0x20)
        }
    }

    /**
     * @notice 소유자의 주소를 입력받아, 해당 소유자가 가지고 있는 토큰의 수량을 반환한다.
     * @param   owner   토큰 소유자
     * @return  소유하고 있는 수량
     */
    function balanceOf(address owner) external view returns (uint256) {
        assembly {
            mstore(BalanceOf_slot_ptr, owner)
            mstore(BalanceOf_next_slot_ptr, ownerInfo.slot)
            mstore(BalanceOf_slot_ptr, and(sload(keccak256(BalanceOf_slot_ptr, 0x40)), 0xffffffffffffffff))
            return(BalanceOf_slot_ptr, BalanceOf_length)
        }
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId
            || interfaceID == type(IERC165).interfaceId;
    }

    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId, ".json"));
    }
}
