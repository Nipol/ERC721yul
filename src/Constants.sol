/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.13;

uint256 constant BalanceOf_slot_ptr = 0x00;
uint256 constant BalanceOf_next_slot_ptr = 0x20;
uint256 constant BalanceOf_length = 0x20;

uint256 constant Approve_ptr = 0x00;
uint256 constant Approve_next_ptr = 0x20;
uint256 constant Approve_Operator_ptr = 0x40;
uint256 constant Approve_Operator_next_ptr = 0x60;
uint256 constant Approve_Owner_ptr = 0x80;

uint256 constant OperatorApproval_ptr = 0x00;
uint256 constant OperatorApproval_next_ptr = 0x20;

uint256 constant TokenReceiver_Signature = (0x150b7a0200000000000000000000000000000000000000000000000000000000);

uint256 constant Event_Transfer_Signature = (0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef);
uint256 constant Event_Approval_Signature = (0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925);
uint256 constant Event_ApprovalForAll_Signature = (0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31);

uint256 constant Error_NotOwnedToken_Signature = (0x9705858800000000000000000000000000000000000000000000000000000000);
uint256 constant Error_NotOperaterable_Signature = (0xce6494fa00000000000000000000000000000000000000000000000000000000);
