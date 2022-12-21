// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAssetStore {
   function updateFundAddress(address fundAddress_) external;
   function withDraw() external;
}