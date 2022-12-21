// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStakingPool {
   event Stake(
      address staker,
      uint256 stakeAmount
   );

   event UnStake(
      address staker,
      uint256 unstakeAmount,
      uint256 rewardAmount
   );

   event Harvest(
      address staker,
      uint256 rewardAmount
   );

   event Deposit(
      address depositor,
      uint256 amount
   );
}