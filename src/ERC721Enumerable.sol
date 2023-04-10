/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is IERC721Enumerable, ERC721 {
    function totalSupply() external view returns (uint256) {
        assembly {
            mstore(0x0, sload(Slot_TokenIndex))
            return(0x0, 0x20)
        }
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        assembly {
            if gt(index, sload(Slot_TokenIndex)) { revert(0, 0) }
            mstore(0x0, index)
            return(0x0, 0x20)
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        assembly {
            mstore(0x0, owner)
            mstore8(0x0, Slot_OwnerInfo)
            if gt(index, and(sload(keccak256(0x0, 0x20)), 0xffffffffffffffff)) { revert(0, 0) }
            mstore(0x0, index)
            return(0x0, 0x20)
        }
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Enumerable).interfaceId
            || interfaceID == type(IERC721Metadata).interfaceId || interfaceID == type(IERC165).interfaceId;
    }

    /**
     * @notice  `to`에게 `quantity`만큼 토큰을 배포합니다.
     * @dev     스토리지 영역이 초기화되지 않았기 때문에, 초기 가스비용이 많이 소모된다.
     * @param   to          토큰을 받을 주소
     * @param   quantity    생성할 토큰 수량
     */
    function _mint(address to, uint256 quantity) internal override {
        assembly {
            let freeptr := mload(0x40)

            // 0x00 현재 토큰 카운터
            mstore(0x0, sload(Slot_TokenIndex))
            mstore(0x20, add(mload(0x0), quantity))

            // 소유자 밸런스 증가
            mstore(0x40, to)
            mstore8(0x40, Slot_OwnerInfo)
            let PoS := keccak256(0x40, 0x20)
            sstore(PoS, add(sload(PoS), quantity))

            for { let tokenId := mload(0x0) } iszero(eq(tokenId, mload(0x20))) { tokenId := add(tokenId, 0x01) } {
                // 저장된 토큰 카운터에 해당하는 정보 저장.
                sstore(tokenId, to)
                log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, tokenId)
            }

            // 토큰 카운터 수량만큼 증가
            sstore(Slot_TokenIndex, mload(0x20))

            // restore free memory pointer
            mstore(0x40, freeptr)
        }
    }

    /**
     * @notice  `to`에게 `quantity`만큼 토큰을 배포합니다.
     * @dev     해당 함수에서는 마지막 인자로, to 주소로 넘길 데이터를 담아야 합니다.
     * @param   to          토큰을 받을 주소
     */
    function _safeMint(address to, uint256 quantity, bytes memory data) internal {
        assembly {
            let freeptr := mload(0x40)

            // 0x00 현재 토큰 카운터
            mstore(freeptr, sload(Slot_TokenIndex))
            // 0x20 더해진 최대 수량
            mstore(add(freeptr, 0x20), add(mload(freeptr), quantity))

            // 소유자 밸런스 증가
            mstore(add(freeptr, 0x40), to)
            mstore8(add(freeptr, 0x40), Slot_OwnerInfo)
            let PoS := keccak256(add(freeptr, 0x40), 0x20)
            sstore(PoS, add(sload(PoS), quantity))

            // to가 contract인가 아닌가
            mstore(add(freeptr, 0x40), gt(extcodesize(to), 0))

            for { let tokenId := mload(freeptr) } iszero(eq(tokenId, mload(add(freeptr, 0x20)))) {
                tokenId := add(tokenId, 0x1)
            } {
                // 저장된 토큰 카운터에 해당하는 정보 저장.
                sstore(tokenId, to)
                log4(0x0, 0x0, Event_Transfer_Signature, 0x0, to, tokenId)

                if mload(add(freeptr, 0x40)) {
                    mstore(add(freeptr, 0x60), TokenReceiver_Signature)
                    mstore(add(freeptr, 0x64), caller())
                    mstore(add(freeptr, 0x84), 0x0)
                    mstore(add(freeptr, 0xa4), tokenId)
                    mstore(add(freeptr, 0xc4), 0x0000000000000000000000000000000000000000000000000000000000000080)

                    if iszero(mload(data)) {
                        mstore(add(freeptr, 0xe4), 0x0000000000000000000000000000000000000000000000000000000000000000)
                    }

                    if gt(mload(data), 0) {
                        mstore(add(freeptr, 0xe4), mload(data))
                        pop(
                            staticcall(
                                gas(),
                                0x04,
                                add(data, 0x20),
                                add(0x20, mload(data)),
                                add(freeptr, 0x104),
                                add(0x20, mload(data))
                            )
                        )
                    }

                    if iszero(
                        and(
                            or(eq(mload(0x0), TokenReceiver_Signature), iszero(returndatasize())),
                            call(gas(), to, 0, add(freeptr, 0x60), add(0x84, add(0x20, mload(data))), 0x0, 0x20)
                        )
                    ) {
                        // revert case
                        let returnDataSize := returndatasize()
                        returndatacopy(0x0, 0x0, returnDataSize)
                        revert(0x0, returnDataSize)
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
