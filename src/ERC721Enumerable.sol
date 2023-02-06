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
            mstore(0x20, Slot_OwnerInfo)
            if gt(index, and(sload(keccak256(0x0, 0x40)), 0xffffffffffffffff)) { revert(0, 0) }
            mstore(0x0, index)
            return(0x0, 0x20)
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
    function _mint(address to, uint256 quantity) internal override {
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

    function _safemint(address, uint256, bytes calldata) internal pure override {
        revert();
    }
}
