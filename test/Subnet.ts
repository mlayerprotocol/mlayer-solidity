import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Subnet", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const IcmToken = await ethers.getContractFactory("IcmToken");
    const _icmToken = await IcmToken.deploy();

    const Subnet = await ethers.getContractFactory("Subnet");
    const _subnet = await Subnet.deploy();

    await _subnet.initialize(_icmToken.getAddress());

    return { _icmToken, _subnet, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have withdrawalEnabled as FALSE", async function () {
      const { _subnet } = await loadFixture(deployContract);

      expect(await _subnet.withdrawalEnabled()).to.equal(false);
    });
  });

  describe("Staking...", function () {
    const subnetId = "001";
    const subnetAmountVal = 2000;
    it(`Should Subnet ${subnetId} -- ${subnetAmountVal}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      await expect(_subnet.stake(subnetId, 0)).to.be.revertedWith(
        "You need to Stake at least some tokens"
      );
      await expect(_subnet.stake(subnetId, subnetAmountVal)).to.be.revertedWith(
        "You need to stake more than the minimum stake"
      );

      // expect(await _subnet.stakeBalance(owner.address)).to.equal(subnetAmountVal);
    });
  });

  describe("Get Balance...", function () {
    const subnetId = "001";
    const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);
    // const minStakable = 5000 * 10**18;
    const minStakable: bigint = BigInt(5000 * 10 ** 18);
    it(`Should Get Balance for Subnet ${subnetId} -- ${subnetAmountVal}`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);
      expect(await _subnet.minStakable()).to.equal(minStakable);
      await _subnet.stake(subnetId, subnetAmountVal);
      expect(await _subnet.getSubnetBalance(subnetId)).to.equal(
        subnetAmountVal
      );

      expect(
        await _subnet.getSubnetAccountBalance(subnetId, owner.getAddress())
      ).to.equal(subnetAmountVal);
    });
  });

  describe("Unstack...", function () {
    const subnetId = "001";
    const subnetAmountVal: bigint = BigInt(6000 * 10 ** 18);

    const minStakable: bigint = BigInt(5000 * 10 ** 18);
    it(`Should Get Unstack`, async function () {
      const { _subnet, _icmToken, owner } = await loadFixture(deployContract);

      await _icmToken.approve(_subnet.getAddress(), subnetAmountVal);

      await _subnet.stake(subnetId, subnetAmountVal);

      await expect( _subnet.unStake(subnetId)).to.be.revertedWith(
        "Withdrawal is not enabled"
      );
      await _subnet.enableWithdrawal(true);
      await expect(_subnet.unStake(subnetId)).to.not.be.revertedWith(
        "Withdrawal is not enabled"
      );
    });
  });
});
