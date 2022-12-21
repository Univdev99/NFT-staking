// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICommonData {
   struct TokenInfo {
      uint256 tokenID;
      uint256 lastUpdateTime;
   }
   struct StakingInfo {
      uint256 stakedAmount;
      TokenInfo[] stakedTokens;
   }
}