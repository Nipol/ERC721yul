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

    uint256 public constant price = 0.1 ether;
    uint256 private _counter;

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

    function mint(address to) external {
        assembly {
            // 소유자 밸런스 증가
            mstore(0x00, to)
            mstore(0x20, ownerInfo.slot)
            let PoS := keccak256(0x00, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 현재 토큰 카운터를 토큰 아이디로 사용하기 위해 메모리에 저장
            mstore(0x00, sload(_counter.slot))

            // 저장된 토큰 카운터에 해당하는 정보 저장.
            mstore(0x20, mload(0x00))
            mstore(0x40, tokenInfo.slot)
            sstore(keccak256(0x20, 0x40), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            // 토큰 카운터 1증가
            sstore(_counter.slot, add(mload(0x00), 0x1))
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external payable {
        assembly {
            if iszero(to) {
                mstore(0x80, Error_NotAllowedZeroAddress_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰 소유자 0x100에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let owner_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(and(sload(owner_ptr), 0xffffffffffffffffffffffffffffffffffffffff), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }
            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))
            sstore(slot_ptr, 0x0)

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

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
            let PoS := keccak256(0x80, 0x40)
            sstore(PoS, sub(sload(PoS), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x80, to)
            PoS := keccak256(0x80, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 토큰ID에 대한 소유자 정보 업데이트
            sstore(owner_ptr, to)

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

            log4(0x0, 0x0, Event_Transfer_Signature, calldataload(0x4), calldataload(0x24), calldataload(0x44))
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            if iszero(to) {
                mstore(0x80, Error_NotAllowedZeroAddress_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰 소유자 0x100에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let owner_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(and(sload(owner_ptr), 0xffffffffffffffffffffffffffffffffffffffff), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))
            sstore(slot_ptr, 0x0)

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

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
            let PoS := keccak256(0x80, 0x40)
            sstore(PoS, sub(sload(PoS), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x80, to)
            PoS := keccak256(0x80, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 토큰ID에 대한 소유자 정보 업데이트
            sstore(owner_ptr, to)

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

            log4(0x0, 0x0, Event_Transfer_Signature, calldataload(0x4), calldataload(0x24), calldataload(0x44))
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            if iszero(to) {
                mstore(0x80, Error_NotAllowedZeroAddress_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰 소유자 0x100에 저장
            mstore(0x80, tokenId)
            mstore(0xa0, tokenInfo.slot)
            let owner_ptr := keccak256(0x80, 0x40)

            // 저장된 토큰 소유자와 from이 같은지 확인
            if iszero(eq(and(sload(owner_ptr), 0xffffffffffffffffffffffffffffffffffffffff), from)) {
                mstore(0x80, Error_NotOwnedToken_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
            mstore(0xa0, tokenAllowance.slot)
            let slot_ptr := keccak256(0x80, 0x40)
            mstore(0x80, sload(slot_ptr))
            sstore(slot_ptr, 0x0)

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

            // 토큰 소유자의 밸런스 값을 1 줄인다
            mstore(0x80, from)
            mstore(0xa0, ownerInfo.slot)
            let PoS := keccak256(0x80, 0x40)
            sstore(PoS, sub(sload(PoS), 0x1))

            // 토큰 수취자의 밸런스 값을 1 증가시킨다
            mstore(0x80, to)
            PoS := keccak256(0x80, 0x40)
            sstore(PoS, add(sload(PoS), 0x1))

            // 토큰ID에 대한 소유자 정보 업데이트
            sstore(owner_ptr, to)

            log4(0x0, 0x0, Event_Transfer_Signature, calldataload(0x4), calldataload(0x24), calldataload(0x44))
        }
    }

    function approve(address approved, uint256 tokenId) external payable {
        assembly {
            if iszero(approved) {
                mstore(0x80, Error_NotAllowedZeroAddress_Signature)
                revert(0x80, 0x4)
            }

            // 현재 토큰 소유자 정보
            mstore(Approve_ptr, tokenId)
            mstore(Approve_next_ptr, tokenInfo.slot)
            mstore(
                Approve_Owner_ptr,
                and(sload(keccak256(Approve_ptr, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff)
            )

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

            log4(0x0, 0x0, Event_Approval_Signature, mload(Approve_Owner_ptr), calldataload(0x4), calldataload(0x24))
        }
        // emit Approval(msg.sender, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        assembly {
            mstore(OperatorApproval_ptr, caller())
            mstore(OperatorApproval_next_ptr, operatorApprovals.slot)
            mstore(OperatorApproval_next_ptr, keccak256(OperatorApproval_ptr, 0x40))
            mstore(OperatorApproval_ptr, operator)
            sstore(keccak256(OperatorApproval_ptr, 0x40), approved)

            mstore(0x0, calldataload(0x24))
            log3(0x0, 0x20, Event_ApprovalForAll_Signature, caller(), calldataload(0x4))
        }
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        assembly {
            mstore(Approve_ptr, tokenId)
            mstore(Approve_next_ptr, tokenAllowance.slot)
            mstore(Approve_ptr, sload(keccak256(Approve_ptr, 0x40)))
            return(Approve_ptr, 0x20)
        }
    }

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

    function ownerOf(uint256 tokenId) external view returns (address) {
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, tokenInfo.slot)
            mstore(0x00, and(sload(keccak256(0x00, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff))
            return(0x00, 0x20)
        }
    }

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
