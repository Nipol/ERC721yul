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
            // 토큰 소유자 밸런스 증가
            mstore(0x40, to)
            mstore(0x60, ownerInfo.slot)
            let PoS := keccak256(0x40, 0x40)
            sstore(PoS, safeAdd(sload(PoS), 0x1))

            // 토큰 카운터
            mstore(0x40, sload(_counter.slot))
            mstore(0x60, mload(0x40))
            mstore(0x80, tokenInfo.slot)
            sstore(keccak256(0x60, 0x40), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            sstore(_counter.slot, safeAdd(mload(0x40), 0x1))

            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable {
        bytes memory cd = abi.encode(data);

        assembly {
            // 현재 토큰 소유자 0x100에 저장
            mstore(0x40, tokenId)
            mstore(0x60, tokenInfo.slot)

            // 저장된 토큰 소유자와 from이 같은지 확인
            switch eq(and(sload(keccak256(0x40, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff), from)
            case true {
                // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장하고 false으로 만든다.
                mstore(0x40, from)
                mstore(0x60, operatorApprovals.slot)
                mstore(0x60, keccak256(0x40, 0x40))
                mstore(0x40, caller())
                mstore(0x40, sload(keccak256(0x40, 0x40)))
                sstore(keccak256(0x40, 0x40), 0x0)

                // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
                mstore(0x80, tokenId)
                mstore(0xa0, tokenAllowance.slot)
                mstore(0x80, sload(keccak256(0x80, 0x40)))
                sstore(keccak256(0x80, 0x40), 0x0)

                // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
                if or(or(eq(caller(), from), mload(0x40)), eq(caller(), mload(0x80))) {
                    // 토큰 소유자의 밸런스 값을 1 줄인다
                    mstore(0x40, from)
                    mstore(0x60, ownerInfo.slot)
                    let PoS := keccak256(0x40, 0x40)
                    sstore(PoS, safeSub(sload(PoS), 0x1))

                    // 토큰 수취자의 밸런스 값을 1 증가시킨다
                    mstore(0x40, to)
                    PoS := keccak256(0x40, 0x40)
                    sstore(PoS, add(sload(PoS), 0x1))

                    // 토큰ID에 대한 소유자 정보 업데이트
                    mstore(0x40, tokenId)
                    mstore(0x60, tokenInfo.slot)
                    sstore(keccak256(0x40, 0x40), to)

                    switch iszero(extcodesize(to))
                    case false {
                        mstore(0x40, 0x150b7a0200000000000000000000000000000000000000000000000000000000)
                        mstore(0x44, caller())
                        mstore(0x64, from)
                        mstore(0x84, tokenId)
                        //TODO: memcpy

                        switch iszero(staticcall(gas(), to, 0x40, add(0x84, data.length), 0x0, 0x20))
                        case true {
                            // revert case
                            let returnDataSize := returndatasize()
                            returndatacopy(0x0, 0x0, returnDataSize)
                            revert(0x0, returnDataSize)
                        }
                        default {
                            // interface impl
                            returndatacopy(0x0, 0x0, returndatasize())
                            if iszero(
                                eq(mload(0x0), 0x150b7a0200000000000000000000000000000000000000000000000000000000)
                            ) { revert(0x0, 0x0) }
                        }
                    }
                }
            }
            default {
                mstore(0x40, shl(224, 0x97058588)) // ERC721_NotOwnedToken
                revert(0x40, 0x4)
            }

            function safeSub(a, b) -> r {
                r := sub(a, b)
                if or(gt(r, a), gt(r, b)) { revert(0, 0) }
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 0x100에 저장
            mstore(0x40, tokenId)
            mstore(0x60, tokenInfo.slot)

            // 저장된 토큰 소유자와 from이 같은지 확인
            switch eq(and(sload(keccak256(0x40, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff), from)
            case true {
                // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장하고 false으로 만든다.
                mstore(0x40, from)
                mstore(0x60, operatorApprovals.slot)
                mstore(0x60, keccak256(0x40, 0x40))
                mstore(0x40, caller())
                mstore(0x40, sload(keccak256(0x40, 0x40)))
                sstore(keccak256(0x40, 0x40), 0x0)

                // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
                mstore(0x80, tokenId)
                mstore(0xa0, tokenAllowance.slot)
                mstore(0x80, sload(keccak256(0x80, 0x40)))
                sstore(keccak256(0x80, 0x40), 0x0)

                // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
                if or(or(eq(caller(), from), mload(0x40)), eq(caller(), mload(0x80))) {
                    // 토큰 소유자의 밸런스 값을 1 줄인다
                    mstore(0x40, from)
                    mstore(0x60, ownerInfo.slot)
                    let PoS := keccak256(0x40, 0x40)
                    sstore(PoS, safeSub(sload(PoS), 0x1))

                    // 토큰 수취자의 밸런스 값을 1 증가시킨다
                    mstore(0x40, to)
                    PoS := keccak256(0x40, 0x40)
                    sstore(PoS, add(sload(PoS), 0x1))

                    // 토큰ID에 대한 소유자 정보 업데이트
                    mstore(0x40, tokenId)
                    mstore(0x60, tokenInfo.slot)
                    sstore(keccak256(0x40, 0x40), to)

                    switch iszero(extcodesize(to))
                    case false {
                        mstore(0x40, 0x150b7a0200000000000000000000000000000000000000000000000000000000)
                        mstore(add(0x40, 0x4), caller())
                        mstore(add(0x40, 0x24), from)
                        mstore(add(0x40, 0x44), tokenId)
                        mstore(add(0x40, 0x64), 0x0000000000000000000000000000000000000000000000000000000000000040)

                        // 4 + (32 * 6)
                        switch iszero(call(gas(), to, 0x0, 0x40, 0xb4, 0x0, 0x20))
                        case true {
                            // revert case
                            let returnDataSize := returndatasize()
                            returndatacopy(0x0, 0x0, returnDataSize)
                            revert(0x0, returnDataSize)
                        }
                        default {
                            // interface impl
                            returndatacopy(0x0, 0x0, returndatasize())
                            if iszero(
                                eq(mload(0x0), 0x150b7a0200000000000000000000000000000000000000000000000000000000)
                            ) { revert(0x0, 0x0) }
                        }
                    }
                }
            }
            default {
                mstore(0x40, shl(224, 0x97058588)) // ERC721_NotOwnedToken
                revert(0x40, 0x4)
            }

            function safeSub(a, b) -> r {
                r := sub(a, b)
                if or(gt(r, a), gt(r, b)) { revert(0, 0) }
            }
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 0x100에 저장
            mstore(0x40, tokenId)
            mstore(0x60, tokenInfo.slot)

            // 저장된 토큰 소유자와 from이 같은지 확인
            switch eq(and(sload(keccak256(0x40, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff), from)
            case true {
                // 현재 토큰에 대한 Operator가 존재한다면 0x40에 불리언 값을 저장하고 false으로 만든다.
                mstore(0x40, from)
                mstore(0x60, operatorApprovals.slot)
                mstore(0x60, keccak256(0x40, 0x40))
                mstore(0x40, caller())
                mstore(0x40, sload(keccak256(0x40, 0x40)))
                sstore(keccak256(0x40, 0x40), 0x0)

                // 현재 토큰의 approve된 유저 정보를 0x80에 저장하고 0으로 만든다.
                mstore(0x80, tokenId)
                mstore(0xa0, tokenAllowance.slot)
                mstore(0x80, sload(keccak256(0x80, 0x40)))
                sstore(keccak256(0x80, 0x40), 0x0)

                // 해당 함수의 호출자가, 토큰의 주인이거나 Operator이거나 Approved 된 이용자인지 확인
                if or(or(eq(caller(), from), mload(0x40)), eq(caller(), mload(0x80))) {
                    // 토큰 소유자의 밸런스 값을 1 줄인다
                    mstore(0x40, from)
                    mstore(0x60, ownerInfo.slot)
                    let PoS := keccak256(0x40, 0x40)
                    sstore(PoS, safeSub(sload(PoS), 0x1))

                    // 토큰 수취자의 밸런스 값을 1 증가시킨다
                    mstore(0x40, to)
                    PoS := keccak256(0x40, 0x40)
                    sstore(PoS, add(sload(PoS), 0x1))

                    // 토큰ID에 대한 소유자 정보 업데이트
                    mstore(0x40, tokenId)
                    mstore(0x60, tokenInfo.slot)
                    sstore(keccak256(0x40, 0x40), to)
                }
            }
            default {
                mstore(0x40, shl(224, 0x97058588)) // ERC721_NotOwnedToken
                revert(0x40, 0x4)
            }

            function safeSub(a, b) -> r {
                r := sub(a, b)
                if or(gt(r, a), gt(r, b)) { revert(0, 0) }
            }
        }
    }

    function approve(address approved, uint256 tokenId) external payable {
        assembly {
            // 현재 토큰 소유자 정보
            mstore(Approve_slot_ptr, tokenId)
            mstore(Approve_next_slot_ptr, tokenInfo.slot)
            mstore(
                Approve_slot_ptr,
                and(sload(keccak256(Approve_slot_ptr, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff)
            )

            // 토큰 소유자가 허용한 오퍼레이터인지
            mstore(0x80, mload(0x100))
            mstore(0xa0, operatorApprovals.slot)
            mstore(0xa0, keccak256(0x40, 0x40))
            mstore(0x80, caller())
            mstore(0x80, sload(keccak256(0x80, 0x40)))

            switch or(eq(caller(), mload(Approve_slot_ptr)), eq(caller(), mload(0x80)))
            case true {
                mstore(Approve_slot_ptr, tokenId)
                mstore(Approve_next_slot_ptr, tokenAllowance.slot)
                sstore(keccak256(Approve_slot_ptr, 0x40), approved)
            }
            default {
                mstore(0x40, shl(224, 0x97058588)) // ERC721_NotOwnedToken
                revert(0x40, 0x4)
            }
        }
        emit Approval(msg.sender, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        assembly {
            mstore(OperatorApproval_slot_ptr, caller())
            mstore(OperatorApproval_next_slot_ptr, operatorApprovals.slot)
            mstore(OperatorApproval_next_slot_ptr, keccak256(OperatorApproval_slot_ptr, 0x40))
            mstore(OperatorApproval_slot_ptr, operator)
            sstore(keccak256(OperatorApproval_slot_ptr, 0x40), approved)
        }

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        assembly {
            mstore(Approve_slot_ptr, tokenId)
            mstore(Approve_next_slot_ptr, tokenAllowance.slot)
            mstore(Approve_slot_ptr, sload(keccak256(Approve_slot_ptr, 0x40)))
            return(Approve_slot_ptr, 0x20)
        }
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        assembly {
            mstore(OperatorApproval_slot_ptr, owner)
            mstore(OperatorApproval_next_slot_ptr, operatorApprovals.slot)
            mstore(OperatorApproval_next_slot_ptr, keccak256(OperatorApproval_slot_ptr, 0x40))
            mstore(OperatorApproval_slot_ptr, operator)
            mstore(OperatorApproval_slot_ptr, sload(keccak256(OperatorApproval_slot_ptr, 0x40)))
            return(OperatorApproval_slot_ptr, 0x20)
        }
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        assembly {
            mstore(0x40, tokenId)
            mstore(0x60, tokenInfo.slot)
            mstore(0x40, and(sload(keccak256(0x40, 0x40)), 0xffffffffffffffffffffffffffffffffffffffff))
            return(0x40, 0x20)
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
