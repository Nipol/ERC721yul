/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "./IERC4494.sol";
import "./IEIP712.sol";
import "ERC721/Constants.sol";

abstract contract ERC4494 is IERC4494, IEIP712 {
    error ERC4494_InvalidSignature();

    error ERC4494_TimeOut();

    bytes32 public constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(string memory name, string memory version) {
        DOMAIN_SEPARATOR = hashDomainSeperator(name, version);
    }

    function permit(address spender, uint256 tokenId, uint256 deadline, bytes calldata) external {
        // 런타임 코드에서 불러오기 까다로운 것들 메모리로 로드
        bytes32 permit_typehash = PERMIT_TYPEHASH;
        bytes32 domain_deparator = DOMAIN_SEPARATOR;

        assembly {
            // 서명 길이 체크
            if iszero(eq(calldataload(0x84), 0x41)) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x0, 0x4)
            }

            // deadline check
            if or(eq(timestamp(), deadline), gt(timestamp(), deadline)) {
                mstore(0x0, Error_TimeOut_Signature)
                revert(0x0, 0x4)
            }
            let pre := "\x19\x01"
            let memPtr := mload(0x40)

            mstore(Permit_ptr, Slot_TokenInfo)
            mstore(Permit_tokenId_ptr, tokenId)
            // 토큰 정보 포지션 키 계산
            let pos := keccak256(Permit_tokenId_ptr, 0x40)
            // 토큰 정보 필드를 0x0에 저장
            mstore(Permit_tokenInfo_ptr, sload(pos))

            // generate hash
            mstore(Permit_ptr, permit_typehash)
            mstore(0x60, spender)
            mstore(0x80, tokenId)
            mstore(0xa0, shr(mload(Permit_tokenInfo_ptr), 0xa0)) // Token Info의 앞쪽 데이터를 가져와야함.
            mstore(0xc0, deadline)

            // 앞의 데이터를 먼저 끝에 넣음
            mstore(0x62, keccak256(Permit_ptr, 0xa0))
            mstore(Permit_ptr, pre)
            mstore(0x42, domain_deparator)

            mstore(Permit_ptr, keccak256(Permit_ptr, 0x42))
            mstore(0x60, 0x0) // initialize for v
            calldatacopy(Permit_sig_v_ptr, 0xe4, 0x2)
            calldatacopy(Permit_sig_r_ptr, 0xa4, 0x20)
            calldatacopy(Permit_sig_s_ptr, 0xc4, 0x20)

            // check malleability
            if gt(mload(0xa0), Signature_s_malleability) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x0, 0x4)
            }

            pop(staticcall(gas(), 0x01, Permit_ptr, 0x80, Permit_ptr, 0x20))

            // 실제 소유자와 주소가 다른 경우
            if or(
                iszero(eq(and(mload(Permit_tokenInfo_ptr), 0xffffffffffffffffffffffffffffffffffffffff), mload(Permit_ptr))),
                iszero(returndatasize())
            ) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x0, 0x4)
            }

            // force approve
            mstore(Permit_ptr, Slot_TokenAllowance)
            sstore(keccak256(Permit_tokenId_ptr, 0x40), spender)

            // nonce 증가
            sstore(pos, add(mload(Permit_tokenInfo_ptr), 0x0000000000000000000000010000000000000000000000000000000000000000))

            // 토큰 인포에서 소유자 정보 넣어줘야 함
            log4(
                0x0,
                0x0,
                Event_Approval_Signature,
                and(mload(Permit_tokenInfo_ptr), 0xffffffffffffffffffffffffffffffffffffffff),
                spender,
                tokenId
            )

            // restore
            mstore(mload(Permit_ptr), memPtr)
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
