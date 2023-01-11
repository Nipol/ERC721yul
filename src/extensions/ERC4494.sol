/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "./IERC4494.sol";
import "./IEIP712.sol";
import "ERC721/Constants.sol";

abstract contract ERC4494 is IERC4494, IEIP712 {
    bytes32 public constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(string memory name, string memory version) {
        bytes32 typehash = EIP712DOMAIN_TYPEHASH;
        DOMAIN_SEPARATOR = hashDomainSeperator(name, version);
    }

    function permit(address spender, uint256 tokenId, uint256 deadline, bytes calldata) external {
        // 런타임 코드에서 불러오기 까다로운 것들 메모리로 로드
        bytes32 permit_typehash = PERMIT_TYPEHASH;
        bytes32 domain_deparator = DOMAIN_SEPARATOR;

        assembly {
            // 서명 길이 체크
            if iszero(eq(calldataload(0x84), 0x41)) {
                mstore(0x0, 0x1)
                revert(0x0, 0x20)
            }

            // deadline check
            // TODO: custom error
            if or(eq(timestamp(), deadline), gt(timestamp(), deadline)) {
                mstore(0x0, 0x2)
                revert(0x0, 0x20)
            }
            let pre := "\x19\x01"
            let memPtr := mload(0x40)

            // 토큰 정보 조회
            mstore(add(memPtr, 0x20), Slot_TokenInfo)
            mstore(memPtr, tokenId)
            // 포지션 키 계산
            let pos := keccak256(memPtr, 0x40)
            // 필드 정보를 0x0에 저장
            mstore(0x0, sload(pos))

            // generate hash
            mstore(memPtr, permit_typehash)
            mstore(add(memPtr, 0x20), spender)
            mstore(add(memPtr, 0x40), tokenId)
            mstore(add(memPtr, 0x60), shr(mload(0x0), 0xa0)) // Token Info의 앞쪽 데이터를 가져와야함.
            mstore(add(memPtr, 0x80), deadline)

            // 앞의 데이터를 먼저 끝에 넣음
            mstore(add(memPtr, 0x22), keccak256(memPtr, 0xa0))
            mstore(memPtr, pre)
            mstore(add(memPtr, 0x2), domain_deparator)

            mstore(memPtr, keccak256(memPtr, 0x42))
            mstore(add(memPtr, 0x20), 0x0)
            calldatacopy(add(memPtr, 0x3f), 0xe4, 0x2)
            calldatacopy(add(memPtr, 0x40), 0xa4, 0x20)
            calldatacopy(add(memPtr, 0x60), 0xc4, 0x20)

            // 호출에 실패한 경우
            if iszero(staticcall(gas(), 0x01, memPtr, 0x80, memPtr, 0x20)) {
                mstore(0x0, 0x3)
                revert(0x0, 0x20)
            }

            // 반환이 없는 경우
            if eq(returndatasize(), 0) {
                mstore(0x0, 0x4)
                revert(0x0, 0x20)
            }

            // 소유자, 또는 반환 주소가 0 경우
            if or(
                iszero(eq(and(mload(0x0), 0xffffffffffffffffffffffffffffffffffffffff), mload(memPtr))),
                eq(0x0, mload(memPtr))
            ) {
                mstore(0x0, 0x5)
                revert(0x0, 0x20)
            }

            // force approve
            mstore(memPtr, tokenId)
            mstore(add(memPtr, 0x20), Slot_TokenAllowance)
            sstore(keccak256(memPtr, 0x40), spender)

            // nonce 증가
            sstore(pos, add(mload(0x0), 0x0000000000000000000000010000000000000000000000000000000000000000))

            // 토큰 인포에서 소유자 정보 넣어줘야 함
            log4(
                0x0,
                0x0,
                Event_Approval_Signature,
                and(mload(0x0), 0xffffffffffffffffffffffffffffffffffffffff),
                spender,
                tokenId
            )
        }
    }

    function nonces(uint256 tokenId) external view returns (uint256) {
        assembly {
            mstore(0xa0, Slot_TokenInfo)
            mstore(0x80, tokenId)
            mstore(
                0x80,
                shr(
                    0xA0,
                    and(
                        sload(keccak256(0x80, 0x40)), 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
                    )
                )
            )
            return(0x80, 0x20)
        }
    }

    /**
     * @dev     Calculates a EIP712 domain separator.
     * @param   name                EIP712 domain name.
     * @param   version             EIP712 domain version.
     * @return  result              EIP712 domain separator.
     */
    function hashDomainSeperator(string memory name, string memory version) private view returns (bytes32 result) {
        bytes32 typehash = EIP712DOMAIN_TYPEHASH;

        assembly {
            let nameHash := keccak256(add(name, 0x20), mload(name))
            let versionHash := keccak256(add(version, 0x20), mload(version))

            let memPtr := mload(0x40)

            mstore(memPtr, typehash)
            mstore(add(memPtr, 0x20), nameHash)
            mstore(add(memPtr, 0x40), versionHash)
            mstore(add(memPtr, 0x60), chainid())
            mstore(add(memPtr, 0x80), address())

            result := keccak256(memPtr, 0xa0)
        }
    }
}
