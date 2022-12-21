const { expect } = require('chai');
const { ethers, network } = require('hardhat');
const { deploy, deployProxy, getAt } = require('../scripts/utils');

const bigNum = num=>(num + '0'.repeat(18))
const smallNum = num=>(parseInt(num)/bigNum(1))
const hour = 60 * 60;

describe('StakingPool', function () {
   before (async function () {
      [
         this.deployer,
         this.account1,
         this.account2,
         this.fundWallet,
         this.tempWallet
      ] = await ethers.getSigners();

      this.rewardsPerHour = 10**6;
      this.stakingNFT = await deploy('StakingNFT', 'Staking NFT', 'SNFT');
      this.rewardToken = await deploy('RewardToken', 'Reward Token', 'RWT');
      this.assetStore = await deploy('AssetStore', this.tempWallet.address, this.rewardToken.address);
      this.stakingPool = await deploy(
         'StakingPool', 
         this.stakingNFT.address, 
         this.rewardToken.address, 
         this.assetStore.address, 
         this.rewardsPerHour, 
         0
      );
   })

   it ('mint NFT', async function() {
      this.mintAmount = 10;
      await this.stakingNFT.connect(this.account1).mintNFT(this.mintAmount);
      expect(await this.stakingNFT.balanceOf(this.account1.address)).to.equal(this.mintAmount);
   })

   it ('staking NFT', async function() {
      await expect(
         this.stakingPool.connect(this.account1).stake([])
      ).to.be.revertedWith('wrong length');

      await this.stakingNFT.connect(this.account1).setApprovalForAll(this.stakingPool.address, true);
      await expect(
         this.stakingPool.connect(this.account1).stake(
            [
               0, 1, 2
            ]
         )
      ).to.be.emit(this.stakingPool, 'Stake')
      .withArgs(
         this.account1.address,
         3
      );
   })

   it ('harvest rewards', async function() {
      await expect(
         this.stakingPool.connect(this.account2).harvest()
      ).to.be.revertedWith('empty staking pool');

      await network.provider.send("evm_increaseTime", [hour]);
      await network.provider.send("evm_mine");

      let pendingRewards = await this.stakingPool.connect(this.account2).getPendingRewards();
      expect(pendingRewards).to.equal(0);

      pendingRewards = await this.stakingPool.connect(this.account1).getPendingRewards();
      expect(pendingRewards).to.equal(this.rewardsPerHour * 3);

      await expect(
         this.stakingPool.connect(this.account1).harvest()
      ).to.be.revertedWith('not enough balance for rewards');

      this.depositAmount = bigNum(10);
      await this.rewardToken.approve(this.stakingPool.address, bigNum(10));
      await expect(
         this.stakingPool.deposit(this.depositAmount)
      ).to.be.emit(this.stakingPool, 'Deposit')
      .withArgs(
         this.deployer.address,
         this.depositAmount
      );

      let oldBal = await this.rewardToken.balanceOf(this.account1.address);
      await expect(
         this.stakingPool.connect(this.account1).harvest()
      ).to.be.emit(this.stakingPool, 'Harvest')
      .withArgs(
         this.account1.address,
         pendingRewards
      );
      let newBal = await this.rewardToken.balanceOf(this.account1.address);
      expect(newBal - oldBal).to.equal(pendingRewards);

      pendingRewards = await this.stakingPool.connect(this.account1).getPendingRewards();
      expect(pendingRewards).to.equal(0);
   })

   it ('add staking pool', async function() {
      await network.provider.send('evm_increaseTime', [hour / 2]);
      await network.provider.send('evm_mine');

      let pendingRewards = await this.stakingPool.connect(this.account1).getPendingRewards();
      expect(pendingRewards).to.equal(0);

      await this.stakingNFT.connect(this.account1).setApprovalForAll(this.stakingPool.address, true);
      await this.stakingPool.connect(this.account1).stake([3, 4]);

      await network.provider.send('evm_increaseTime', [hour]);
      await network.provider.send('evm_mine');

      pendingRewards = await this.stakingPool.connect(this.account1).getPendingRewards();
      expect(pendingRewards).to.equal(5 * this.rewardsPerHour);
   })

   it ('change APY and fee rate, and unstake', async function() {
      let APY = await this.stakingPool.getAPY();
      expect(APY).to.equal(this.rewardsPerHour);

      let feeRate = await this.stakingPool.getFeeRate();
      expect(feeRate).to.equal(0);
      await this.stakingPool.updateFeeRate(20 * 10**2);
      feeRate = await this.stakingPool.getFeeRate();
      expect(feeRate).to.equal(20 * 10**2);

      let pendingRewards = await this.stakingPool.connect(this.account1).getPendingRewards();
      let fee = pendingRewards * 0.2;
      pendingRewards = pendingRewards * 0.8;

      await expect(
         this.stakingPool.connect(this.account1).unstake()
      ).to.be.emit(this.stakingPool, 'UnStake')
      .withArgs(
         this.account1.address,
         5,
         pendingRewards
      );
   })

   it ('try to withDraw', async function() {
      await this.assetStore.updateFundAddress(this.fundWallet.address);
      let oldAmount = await this.rewardToken.balanceOf(this.fundWallet.address);
      await this.assetStore.withDraw();
      let newAmount = await this.rewardToken.balanceOf(this.fundWallet.address);
      
      expect (newAmount - oldAmount).to.equal(10 ** 6);
   })
})