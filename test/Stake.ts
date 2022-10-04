import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Stake", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("ERC20");
    const _icmToken = await IcmToken.deploy();

    const Stake = await ethers.getContractFactory("Stake");
    const _stake = await Stake.deploy(_icmToken.address);

    return { _icmToken, _stake, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have withdrawalEnabled as FALSE", async function () {
      const { _stake } = await loadFixture(deployOneYearLockFixture);

      expect(await _stake.withdrawalEnabled()).to.equal(false);
      await expect(_stake.unStake()).to.be.revertedWith(
        "Withdrawal is not enabled"
      );
    });
  });

  describe("Staking...", function () {
    const stakeVal = 2000;
    it(`Should Stake ${stakeVal}`, async function () {
      const { _stake, _icmToken, owner } = await loadFixture(
        deployOneYearLockFixture
      );

      await _icmToken.approve(_stake.address, stakeVal);

      await expect(_stake.stake(stakeVal)).to.not.be.revertedWith(
        "Insufficient Allowance"
      );

      expect(await _stake.stakeBalance(owner.address)).to.equal(stakeVal);
    });
  });


  describe("Get Level", function () {
    const level = 1;
    const stakeVal = 2000;
    it(`Level is : ${level}`, async function () {
      const { _stake,_icmToken, owner } = await loadFixture(
        deployOneYearLockFixture
      );

      await _icmToken.approve(_stake.address, stakeVal);

      await expect(_stake.stake(stakeVal)).to.not.be.revertedWith(
        "Insufficient Allowance"
      );
      await _stake.stakeBalance(owner.address)

      expect(await _stake.getNodeLevel(owner.address)).to.equal(level);
    });
  });
});
