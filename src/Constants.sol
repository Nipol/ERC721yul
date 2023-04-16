/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.4;

uint256 constant BalanceOf_slot_ptr = 0x00;
uint256 constant BalanceOf_next_slot_ptr = 0x20;
uint256 constant BalanceOf_length = 0x20;

uint256 constant Approve_ptr = 0x00;
uint256 constant Approve_next_ptr = 0x20;
uint256 constant Approve_Operator_owner_ptr = 0x40;
uint256 constant Approve_Operator_operator_ptr = 0x60;
uint256 constant Approve_Operator_slot_ptr = 0x80;

uint256 constant OperatorApproval_owner_ptr = 0x00;
uint256 constant OperatorApproval_operator_ptr = 0x20;
uint256 constant OperatorApproval_slot_ptr = 0x40;

uint256 constant Permit_tokenInfo_ptr = 0x00;
uint256 constant Permit_tokenId_ptr = 0x20;
uint256 constant Permit_ptr = 0x40;
uint256 constant Permit_sig_v_ptr = 0x7f;
uint256 constant Permit_sig_r_ptr = 0x80;
uint256 constant Permit_sig_s_ptr = 0xa0;

uint256 constant Signature_s_malleability = (0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);

uint256 constant TokenReceiver_Signature = (0x150b7a0200000000000000000000000000000000000000000000000000000000);

uint256 constant Event_Transfer_Signature = (0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef);
uint256 constant Event_Approval_Signature = (0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925);
uint256 constant Event_ApprovalForAll_Signature = (0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31);

uint256 constant Error_ExistedToken_Signature = (0xc1f55e86);
uint256 constant Error_NotOwnedToken_Signature = (0x97058588);
uint256 constant Error_NotOperaterable_Signature = (0xce6494fa);

uint256 constant Error_InvalidSignature_Signature = (0x9c5deda7);
uint256 constant Error_TimeOut_Signature = (0xf9199e3f);

// (uint256(keccak256('ERC721yul.tokenIndex')) - 1)[:1]
uint8 constant Slot_TokenIndex = (0x50);

// (uint256(keccak256('ERC721yul.ownerInfo')) - 1)[:1]
uint8 constant Slot_OwnerInfo = (0xe3);

// (uint256(keccak256('ERC721yul.tokenAllowance')) - 1)[:1]
uint8 constant Slot_TokenAllowance = (0xcc);

// (uint256(keccak256('ERC721yul.operatorApprovals')) - 1)[:1]
uint8 constant Slot_OperatorApprovals = (0xff);
