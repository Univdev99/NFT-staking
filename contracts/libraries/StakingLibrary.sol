// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../interfaces/ICommonData.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

library StakingLibrary {
   function addStakingPool(
      ICommonData.StakingInfo storage info_,
      uint256 curTime_,
      uint256[] memory tokenIDs_
   ) internal {
      info_.stakedAmount += tokenIDs_.length;
      for (uint256 i = 0; i < tokenIDs_.length; i ++) {
         info_.stakedTokens.push(ICommonData.TokenInfo({
            tokenID: tokenIDs_[i],
            lastUpdateTime: curTime_
         }));
      }
   }

   function calcPendingRewards(
      ICommonData.StakingInfo memory info_,
      uint256 curTime_,
      uint256 rewardsRate_
   ) internal pure returns(uint256) {
      uint256 pendingRewards = 0;
      for (uint256 i = 0; i< info_.stakedAmount; i ++) {
         uint256 pendingTime = (curTime_ - info_.stakedTokens[i].lastUpdateTime) / 1 hours;
         pendingRewards += pendingTime * rewardsRate_;
      }
      
      return pendingRewards;
   }

   function updateTime(
      ICommonData.StakingInfo storage info_,
      uint256 curTime_
   ) internal {
      uint256 length = info_.stakedTokens.length;
      for (uint256 i = 0; i < length; i ++) {
         info_.stakedTokens[i].lastUpdateTime = curTime_;
      }
   }

   function formatStakingPool(
      ICommonData.StakingInfo storage info_
   ) internal {
      for (uint256 i = 0; i < info_.stakedAmount; i ++) {
         info_.stakedTokens.pop();
      }
      info_.stakedAmount = 0;
   }
}