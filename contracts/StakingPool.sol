// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICommonData.sol";
import "./interfaces/IStakingPool.sol";
import "./libraries/StakingLibrary.sol";

import "hardhat/console.sol";

contract StakingPool is ReentrancyGuard, Ownable, ERC721Holder, ICommonData, IStakingPool {
   using SafeERC20 for IERC20;
   using StakingLibrary for StakingInfo;

   mapping(address => StakingInfo) private stakingInfos;
   address private assetStore;

   IERC721 private stakingNFT;
   IERC20 private rewardToken;
   uint256 private rewardsPerHour;
   uint16 private feeRate;  // * 1e2: 1 * 1e2 = 1 %

   uint256[] private array;

   constructor(
      address stakingNFT_,
      address rewardToken_,
      address assetStore_,
      uint256 rewardsPerhour_,
      uint16 feeRate_
   ) {
      assetStore = assetStore_;
      stakingNFT = IERC721(stakingNFT_);
      rewardToken = IERC20(rewardToken_);
      rewardsPerHour = rewardsPerhour_;
      feeRate = feeRate_;
   }

   function updateFeeRate(uint16 feeRate_) external onlyOwner {
      feeRate = feeRate_;
   }

   function deposit(uint256 amount_) external onlyOwner {
      rewardToken.safeTransferFrom(msg.sender, address(this), amount_);
      emit Deposit(msg.sender, amount_);
   }

   function stake(uint256[] memory tokenIDs_) external {
      uint256 length = tokenIDs_.length;
      address sender = msg.sender;
      require (length > 0, 'wrong length');
      for (uint256 i = 0; i < length; i ++) {
         stakingNFT.safeTransferFrom(sender, address(this), tokenIDs_[i]);
      }

      stakingInfos[sender].addStakingPool(block.timestamp, tokenIDs_);

      emit Stake(sender, tokenIDs_.length);
   }

   function harvest() external {
      address sender = msg.sender;
      require (stakingInfos[sender].stakedAmount > 0, 'empty staking pool');
      uint256 curTime = block.timestamp;
      uint256 rewards = stakingInfos[sender].calcPendingRewards(curTime, rewardsPerHour);
      require (rewards <= rewardToken.balanceOf(address(this)), 'not enough balance for rewards');

      stakingInfos[sender].updateTime(curTime);

      if (rewards > 0) {
         rewards = _takeFeeAndTransfer(rewards);
      }

      emit Harvest(
         sender,
         rewards
      );
   }

   function unstake() external {
      address sender = msg.sender;
      require (stakingInfos[sender].stakedAmount > 0, 'empty staking pool');
      StakingInfo memory info = stakingInfos[sender];
      stakingInfos[sender].formatStakingPool();
      uint256 curTime = block.timestamp;
      uint256 rewardsAmount = info.calcPendingRewards(curTime, rewardsPerHour);
      if (rewardsAmount > 0) {
         rewardsAmount = _takeFeeAndTransfer(rewardsAmount);
      }

      for (uint256 i = 0; i < info.stakedTokens.length; i ++) {
         stakingNFT.safeTransferFrom(address(this), sender, info.stakedTokens[i].tokenID);
      }

      emit UnStake(
         sender,
         info.stakedTokens.length,
         rewardsAmount
      );
   }

   function getPendingRewards() external view returns(uint256) {
      return stakingInfos[msg.sender].calcPendingRewards(block.timestamp, rewardsPerHour);
   }

   function getAPY() external view returns(uint256) {
      return rewardsPerHour;
   }

   function getFeeRate() external view returns(uint16) {
      return feeRate;
   }

   function _takeFeeAndTransfer(uint256 amount_) internal returns(uint256) {
      uint256 feeAmount = amount_ * uint256(feeRate) / 1e4;
      uint256 rewardAmount = amount_ - feeAmount;

      if (feeAmount > 0) {
         rewardToken.safeTransfer(assetStore, feeAmount);        
      }

      rewardToken.safeTransfer(msg.sender, rewardAmount);

      return rewardAmount;
   }
}