/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

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

    /**
     * @notice  소유자의 서명으로 approve를 수행하는 함수
     * @param   spender     approve 대상 주소
     * @param   tokenId     spender가 사용할 토큰 아이디
     * @param   deadline    permit의 만료시간 타임스탬프
     * @param   signature   서명 데이터
     */
    function permit(address spender, uint256 tokenId, uint256 deadline, bytes calldata signature) external {
        // 런타임 코드에서 불러오기 까다로운 것들 메모리로 로드
        bytes32 permit_typehash = PERMIT_TYPEHASH;
        bytes32 domain_deparator = DOMAIN_SEPARATOR;

        assembly {
            // 서명 길이 체크
            if iszero(eq(signature.length, 0x41)) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x1c, 0x4)
            }

            // deadline check
            if or(eq(timestamp(), deadline), gt(timestamp(), deadline)) {
                mstore(0x0, Error_TimeOut_Signature)
                revert(0x1c, 0x4)
            }
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
            mstore(Permit_ptr, "\x19\x01")
            mstore(0x42, domain_deparator)

            mstore(Permit_ptr, keccak256(Permit_ptr, 0x42))
            mstore(0x60, 0x0) // initialize for v
            calldatacopy(Permit_sig_v_ptr, 0xe4, 0x2)
            calldatacopy(Permit_sig_r_ptr, 0xa4, 0x20)
            calldatacopy(Permit_sig_s_ptr, 0xc4, 0x20)

            // check malleability
            if gt(mload(0xa0), Signature_s_malleability) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x1c, 0x4)
            }

            pop(staticcall(gas(), 0x01, Permit_ptr, 0x80, Permit_ptr, 0x20))

            // 실제 소유자와 주소가 다른 경우, 반환 주소가 없거나 0x0인 경우.
            if or(
                iszero(
                    eq(and(mload(Permit_tokenInfo_ptr), 0xffffffffffffffffffffffffffffffffffffffff), mload(Permit_ptr))
                ),
                iszero(returndatasize())
            ) {
                mstore(0x0, Error_InvalidSignature_Signature)
                revert(0x1c, 0x4)
            }

            // force approve
            mstore(Permit_ptr, Slot_TokenAllowance)
            sstore(keccak256(Permit_tokenId_ptr, 0x40), spender)

            // nonce 증가
            sstore(
                pos,
                add(mload(Permit_tokenInfo_ptr), 0x0000000000000000000000010000000000000000000000000000000000000000)
            )

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

    /**
     * @notice  NFT의 nonce를 반환하는 함수, permit를 구성할 때 사용
     * @param   tokenId nonce를 조회하고자 하는 NFT 아이디
     * @return  nonce uint256으로 반환
     */
    function nonces(uint256 tokenId) external view returns (uint256) {
        assembly {
            mstore(0x20, Slot_TokenInfo)
            mstore(0x00, tokenId)
            mstore(0x00, shr(0xA0, sload(keccak256(0x00, 0x40))))
            return(0x00, 0x20)
        }
    }

    /**
     * @dev     EIP712 domain separator 계산하는 함수
     * @param   name    EIP712 도메인 네임.
     * @param   version EIP712 도메인 버전.
     * @return  result  EIP712 domain separator.
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
