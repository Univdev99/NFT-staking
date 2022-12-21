// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAssetStore.sol";

contract AssetStore is Ownable, IAssetStore {
   using SafeERC20 for IERC20;
   address private fundAddress;
   IERC20 private Currency;

   constructor(
      address fundAddress_,
      address currencyAddress_
   ) {
      fundAddress = fundAddress_;
      Currency = IERC20(currencyAddress_);
   }

   function updateFundAddress(address fundAddress_) external onlyOwner override {
      fundAddress = fundAddress_;
   }

   function withDraw() external onlyOwner override {
      uint256 balance = Currency.balanceOf(address(this));
      if (balance > 0) {
         Currency.safeTransfer(fundAddress, balance);
      }
   }
}